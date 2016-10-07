

# tblui.el

Define tabulated-list based UI easily.

# Motivation

`tabulated-list` is the official library which implements basic functionality for table like buffer.
Implementing nice UI on top of this, however, you still needs to write view/UI logic.

Motivation for this package is to reduce boilerplate works required to make an table-like UI.
This is achieved by utilizing following 2 packages:

  * `magit-popup` : for magit-like popup UI
  * `tablist` : for dired like UI

The user of this package can focus on writing the logic of table entity creation/interaction.

In this document, the UI defined via this package is referred as tblui.

# How to use

I believe giving actual example would be the most descriptory.
Below is the snippet from https://github.com/Yuki-Inoue/aws.el .

```
(tblui-define
 aws-instances
 aws-instances-get-tabulated-list-entries
 [("Repository" 10 nil)
  ("InstType" 10 nil)
  ("Name" 30 nil)
  ("Status" 10 nil)
  ("IP" 15 nil)
  ("Settings" 20 nil)]
 ((:key "I"
   :name aws-instances-inspect-popup
   :funcs ((?I "Inspect" aws-instances-inspect-instances)))

  (:key "S"
   :name aws-instances-state-popup
   :funcs ((?O "Stop" aws-instances-stop-instances)
           (?R "Reboot" aws-instances-reboot-instances)
           (?T "Terminate" aws-instances-terminate-instances)
           (?S "Start" aws-instances-start-instances)))

  (:key "A"
   :name aws-instances-action-popup
   :funcs ((?R "Rename Instance" aws-instances-rename-instance)))

  (:key "C"
   :name aws-instances-configure-popup
   :funcs ((?C "Append ssh configs to ~/.ssh/config" aws-instances-configure-ssh-config)))

  (:key "B"
   :name aws-instances-backup-popup
   :funcs ((?I "Inspect" aws-instances-inspect-backup-instances)
           (?B "Backup" aws-instances-backup-instances)))
  ))
```

The macro defines all the functions/keybinds/popups required for the UI,
and the UI can be visited by calling `aws-instances-goto-ui` function in this example.


The synopsis of this macro is shown below:

```
(tblui-define TBLUI-NAME ENTRIES-PROVIDER TABLE-LAYOUT POPUP-DEFINITIONS)
```

where

 * `TBLUI-NAME` : the symbol name of defining tblui.  It will be used as prefix for functions defined via this macro.
 * `ENTRIES-PROVIDER` : the function which provides tabulated-list-entries
 * `TABLE-LAYOUT` : the `tabulated-list-format` to be used for the tblui.
 * `POPUP-DEFINITIONS` : list of popup definition.
   A popup definition is an plist of `(:key KEY :name NAME :funcs FUNCTIONS)`.  KEY is the key to be bound for the defined magit-popup.  NAME is the name for defined magit-popup.  FUNCTIONS is the list of action definition.  Action definition is a list of 3 elements, which is `(ACTIONKEY DESCRIPTION FUNCTION)`.  ACTIONKEY is the key to be used as action key in the magit-popup.  DESCRIPTION is the description of the action.
   FUNCTION is the logic to be called for this UI.  It is the elisp function which receives the IDs of tabulated-list entry, and do what ever operation.

With this macro `TBLUI-NAME-goto-ui` function is defined.  Calling this function will popup and switch to the tblui buffer.
