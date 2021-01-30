type extensionContext
type disposable
type position
type range
type selection
type statusBarItem
type textDocument
type textEditor
type textEditorEdit
type textLine

@bs.module external vscode : Js.t<'a> = "vscode"

module StatusBarAlignment = {
    type t;

    let left : t = vscode["_StatusBarAlignment"]["_Left"]
    let right : t = vscode["_StatusBarAlignment"]["_Right"]
}

module TextEditorCursorStyle = {
  type t

  let block : t = vscode["_TextEditorCursorStyle"]["_Block"]
  let line : t = vscode["_TextEditorCursorStyle"]["_Line"]
}

module TextEditorRevealType = {
  type t

  let atTop : t = vscode["_TextEditorRevealType"]["_AtTop"]
  let default : t = vscode["_TextEditorRevealType"]["_Default"]
  let inCenter : t = vscode["_TextEditorRevealType"]["_InCenter"]
  let inCenterIfOUtsideViewport : t = vscode["_TextEditorRevealType"]["_InCenterIfOutsideViewport"]
}

module Vscode = {
  module Commands = {
    let executeCommand : string => unit =
      command => vscode["commands"]["executeCommand"](command)

    let executeCommandWithArg : string => 'a => unit =
      (command, arg) => vscode["commands"]["executeCommand"](command, arg)

    let registerCommand : string => ('a => unit) => disposable =
      (name, callback) => vscode["commands"]["registerCommand"](name, callback)
  };

  module Window = {
    let activeTextEditor : unit => option<textEditor> =
      () => Js.Undefined.toOption(vscode["window"]["activeTextEditor"])

    let createStatusBarItem : StatusBarAlignment.t => statusBarItem =
      alignment => vscode["window"]["createStatusBarItem"](alignment)

    let onDidChangeActiveTextEditor : (textEditor => unit) => disposable =
      listener => vscode["window"]["onDidChangeActiveTextEditor"](listener)

    let showInformationMessage : string => unit =
      message => vscode["window"]["showInformationMessage"](message)

    let showQuickPick : array<'a> => Js.t<{..}> => Js.Promise.t<(Js.undefined<'a>)> =
      (items, options) => vscode["window"]["showQuickPick"](items, options)
  }
}

module ExtensionContext = {
  @bs.get external subscriptions: extensionContext => array<disposable> = "subscriptions"  
}

module Position = {
  type t = position

  @bs.module("vscode") @bs.new external make : int => int => t = "Position"

  @bs.get external character : t => int = "character"
  @bs.get external line : t => int = "line"

  @bs.send external translate : ~line: int=? => ~char : int=? => position = "translate"
  @bs.send external with_ : ~line : int=? => ~char: int=? => position = "with"
}

module Range = {
  type t = range

  @bs.module("vscode") @bs.new external make : ~start: position => ~end_: position => t = "Range"
}

module Selection = {
  type t = selection

  @bs.module("vscode") @bs.new external make : ~anchor: position => ~active: position => t = "Selection"

  external asRange : t => range = "%identity"

  @bs.get external active : t => position = "active"
  @bs.get external anchor : t => position = "anchor";
  @bs.get external end_ : t => position = "end"
  @bs.get external isEmpty : t => bool = "isEmpty"
  @bs.get external isReversed : t => bool = "isReversed"
  @bs.get external isSingleLine : t => bool = "isSingleLine"
  @bs.get external start : t => position = "start"

  @bs.send external with_ : ~start: position=? => ~end_: position=? => t = "with"
}

module StatusBarItem = {
  type t = statusBarItem

  @bs.set external setText : t => string => unit = "text"

  @bs.send external show : unit => unit = "show"
}

module TextDocument = {
  type t = textDocument

  @bs.get external lineCount : t => int = "lineCount"

  @bs.send external getText : ~range: range=? => string = "getText"
  @bs.send external lineAt : int => textLine = "lineAt"
  @bs.send external lineAtPosition : position => textLine = "lineAt"
}

module TextEditor = {
  type t = textEditor

  module Options = {
    type t

    @bs.set external setCursorStyle : t => TextEditorCursorStyle.t => unit = "cursorStyle"
  }

  @bs.get external document : t => textDocument = "document"
  @bs.get external options : t => Options.t = "options"
  @bs.get external selection : t => selection = "selection"
  @bs.set external setSelection : t => selection => unit = "selection"
  @bs.get external selections : t => array<selection> = "selections"
  @bs.set external setSelections : t => array<selection> => unit = "selections"

  @bs.send external edit : (textEditorEdit => unit) => Js.Promise.t<bool> = "edit"
  @bs.send external revealRange : range => TextEditorRevealType.t => unit = "revealRange"
}

module TextEditorEdit = {
  type t = textEditorEdit

  @bs.send external delete : selection => unit = "delete"
  @bs.send external insert : position => string => unit = "insert"
  @bs.send external replace : range => string => unit = "replace"
}

module TextLine = {
  type t = textLine

  @bs.get external text : t => string = "text"
}