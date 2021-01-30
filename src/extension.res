open Binding

let activate = context => {
  Js.log("Congratulations, your extension \"vrc\" is now active!")

  let disposable = Vscode.Commands.registerCommand(
    "vrc.sayHello", () => {
        Vscode.Window.showInformationMessage("Hello, world!")
    }
  )

  let subscriptions = context -> ExtensionContext.subscriptions
  let subscribe = x => x -> Js.Array.push(subscriptions) -> ignore

  disposable -> subscribe
}

let deactivate = () => ()
