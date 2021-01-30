// TODO: Add Proxy, tls
// other Encoding options
// callback support

open Belt.Option

// A Simple Wrapper of net.Socket module of node.js
module Conn = {
    type socket;

    @bs.module("net") external createConnection : int => string => socket = "createConnection"

    @bs.get external readyState : socket => string = "readyState"

    @bs.send external write : socket => string => bool = "write"
    @bs.send external setTimeout : socket => int => socket = "setTimeout"
    @bs.send external setEncoding : socket => string => socket = "setEncoding"
    @bs.send external destroy : socket => unit = "destroy"
    @bs.send external end : socket => unit = "end"

    let requestedDisconnect = ref(false);
}

module Client = {
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
        ping: int,
        pingTimeout: int
    }

    type webirc = {
        ip: string,
        host: string,
        pass: string
    }

    let nick = ref("")
    let hostMask = ref("")
    let maxLineLength = ref(0)

    // from irssi
    let updateMaxLineLength = () => {
        maxLineLength := 497 - nick.contents->Js.String.length - hostMask.contents->Js.String.length
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
                ping: 180,
                pingTimeout: 20,
            }
            a
        }

    let connectListener = (conn, opt) => {
        // TODO webirc and sasl
        conn->send(["NICK", opt.nickname])
        nick := opt.nickname
        updateMaxLineLength()
        conn->send(["USER", opt.username, 8->Belt.Int.toString, "*", opt.realname])

        // TODO cyclingPing
    }

    let connect = (opt, retry) => {
        let conn = Conn.createConnection(opt.port, opt.server)
        conn->Conn.setTimeout(0)->ignore
        conn->Conn.setEncoding("utf8")->ignore
        // TODO cyclingPing
    }

    let disconnect = (conn, msg) => {
        if conn->Conn.readyState == "open" {
            conn->send(["QUIT", msg])
        }
        Conn.requestedDisconnect := true
        conn->Conn.end
    }

    let end = (conn) => {
        // TODO cyclingPing
        conn->Conn.destroy
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

        if Conn.requestedDisconnect.contents == false {
            Conn.write(conn, Js.Array.joinWith(" ", args) ++ "\r\n")->ignore
        }
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