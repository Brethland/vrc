// TODO: Add Proxy, tls
// other Encoding options
// callback support
// option build

open Belt.Option

// A Simple Wrapper of net.Socket module of node.js
module Conn = {
    type socket;

    @bs.module("net") external createConnection : int => string => socket = "createConnection"

    @bs.get external readyState : socket => string = "readyState"

    @bs.send external write : socket => string => bool = "write"
    @bs.send external setTimeout : socket => int => socket = "setTimeout"
    @bs.val external setTimeout_ : (unit => 'a) => int => 'a = "setTimeout"
    @bs.send external setEncoding : socket => string => socket = "setEncoding"
    @bs.send external destroy : socket => unit = "destroy"
    @bs.send external end : socket => unit = "end"
}

module Client = {
    // A Wrapper of event module of node.js, be careful you must ensure
    // that object has EventEmitter class
    @bs.send external addListener : 'a => string => ('b => unit) => 'c = "addListener"
    @bs.send external emit : 'a => string => bool = "emit"

    @bs.new external newReg : string => Js.Re.t = "RegExp"

    type webirc = {
        ip: string,
        host: string,
        pass: string
    }

    type option = {
        server: string,
        port: int,
        nickname: string,
        password: string,
        username: string,
        realname: string,
        nickPass: string,
        usermode: string,
        mutable channels: array<string>,
        isSasl: bool,
        webIrc: option<webirc>,
        retryCount: int,
        retryDelay: int,
    }

    let nick = ref("")
    let hostMask = ref("")
    let maxLineLength = ref(0)
    let requestedDisconnect = ref(false);
    let receiveBuffer = ref([])

    // from irssi
    let updateMaxLineLength = () => {
        maxLineLength := 497 - nick.contents->Js.String.length - hostMask.contents->Js.String.length
    }

    let send = (conn, command) => {
        let args = Js.Array.copy(command)

        let patternA = %re("/\s/")
        let patternB = %re("/^:/")
        
        let len = Js.Array.length(args)

        if Js.String.match_(patternA, args[len - 1])->isSome == true 
          || Js.String.match_(patternB, args[len - 1])->isSome == true
          || args[len - 1] == "" {
            args[len - 1] = ":" ++ args[len - 1]
        }

        if requestedDisconnect.contents == false {
            Conn.write(conn, Js.Array.joinWith(" ", args) ++ "\r\n")->ignore
        }
    }

    let newClient =
        (~server, ~port=6667, ~password=?, ~nickname) => {
            let a = {
                server: server,
                port: port,
                nickname: nickname,
                password: switch password {
                            | None => ""
                            | Some(a) => a
                },
                username: "Rescript IRC Bot",
                realname: "Rescript IRC Bot",
                nickPass: "",
                usermode: "+RB -x",
                channels: [],
                isSasl: false,
                webIrc: None,
                retryCount: 10,
                retryDelay: 5,
            }
            a
        }

    let connectListener = (conn, opt) => {
        if opt.webIrc->isSome == true {
            let args = opt.webIrc->getExn
            conn->send(["WEBIRC", args.pass, opt.username, args.host, args.ip])->ignore
        }
        if opt.isSasl == true {
            conn->send(["CAP REQ", "sasl"])
        } else {
            conn->send(["PASS", opt.password])
        }
        conn->send(["NICK", opt.nickname])
        nick := opt.nickname
        updateMaxLineLength()
        conn->send(["USER", opt.username, 8->Belt.Int.toString, "*", opt.realname])
        // TODO cyclingPing

        // TODO emit signal
    }

    let rec connect = (opt, retry) => {
        let conn = Conn.createConnection(opt.port, opt.server)
        conn->Conn.setTimeout(0)->ignore
        conn->Conn.setEncoding("utf8")->ignore
        // TODO cyclingPing

        conn->addListener("data", (chunk: string) => {
            // TODO cyclingPing
            Js.Array.push(chunk, receiveBuffer.contents)->ignore

            let lines = Js.Array.map(op => op->getExn,
                Js.String.splitByRe(newReg("\r\n|\r|\n"), Js.Array.toString(receiveBuffer.contents)))

            if Js.Array.pop(lines)->getExn == "" {
                receiveBuffer := []
                Js.Array.forEach((line) => {
                    if Js.String.length(line) > 0 {
                        114514->ignore
                        // TODO Parse and emit signal
                    }
                }, lines)->ignore
            }
        })->ignore
        conn->addListener("close", () => {
            if requestedDisconnect.contents == false && retry < opt.retryCount {
                Conn.setTimeout_(() => connect(opt, retry + 1)->ignore, opt.retryDelay)->ignore
            }
        })->ignore
        conn->addListener("error", exception_ => {
            Js.log(exception_)
        })->ignore
        conn
    }

    let disconnect = (conn, msg) => {
        if conn->Conn.readyState == "open" {
            conn->send(["QUIT", msg])
        }
        requestedDisconnect := true
        conn->Conn.end
    }

    let end = (conn) => {
        // TODO cyclingPing
        conn->Conn.destroy
    }

    let join = (conn, opt, channel) => {
        let channels = channel->Js.String.split(" ")
        Belt.Array.map(channels, (x) => { 
            conn->send(["JOIN", x])
            if Js.Array.indexOf(x, opt.channels) == -1 {
                Js.Array.push(x, opt.channels)->ignore
            }
        })->ignore
    }

    let part = (conn, opt, channel, ~msg=?, ()) => {
        switch msg {
            | None => conn->send(["PART", channel])
            | Some(msg) => conn->send(["PART", channel, msg])
        }
        if Js.Array.indexOf(channel, opt.channels) != -1 {
            Js.Array.spliceInPlace(
                ~pos=Js.Array.indexOf(channel, opt.channels), 
                ~remove=1, 
                ~add=[], 
                opt.channels)->ignore
        }
    }

    let whois = (conn, nickname) => {
        conn->send(["WHOIS", nickname])
    }
}