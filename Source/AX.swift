//
//  AX.swift
//  Menuet
//
//

import ApplicationServices
import Foundation


enum AX {
  typealias Action = AXAction
  typealias Attribute = AXAttribute
  typealias APIError = AXAPIError
  typealias Error = AXElementError
  typealias Role = AXRole
}


/**
 Enumeration of known accessibility UI element actions.

 Swift enum values must be primitive so the CFSTR values
 defined in AXActionConstants.h. The enum vales below were
 generated with the following script.

 ```sh
 grep '^\#define.*Action.*CFSTR' AXActionConstants.h \
 | sed -E -e 's/^\#define kAX[A-Za-z]+Action//' \
 | tr -d '[:blank:]' \
 | sed -E -e 's/^CFSTR\("AX([A-Za-z]+)"\)/case \1 = "AX\1"/' \
 | sort
 ```
 */
enum AXAction: String, RawRepresentable {
  case Cancel = "AXCancel"
  case Confirm = "AXConfirm"
  case Decrement = "AXDecrement"
  case Increment = "AXIncrement"
  case Pick = "AXPick"
  case Press = "AXPress"
  case Raise = "AXRaise"
  case ShowAlternateUI = "AXShowAlternateUI"
  case ShowDefaultUI = "AXShowDefaultUI"
  case ShowMenu = "AXShowMenu"
}


/**
 Enumeration of known accessibility UI element attribute names.

 Swift enum values must be primitive so the CFSTR values defined in
 AXAttributeConstants.h. The enum vales below were generated with the following
 script.

 ```sh
 grep '^\#define.*Attribute.*CFSTR' AXAttributeConstants.h \
 | sed -E -e 's/^\#define kAX[A-Za-z]+Attribute//' \
 | tr -d '[:blank:]' \
 | sed -E -e 's/^CFSTR\("AX([A-Za-z]+)"\)/case \1 = "AX\1"/' \
 | sort
 ```
 */
enum AXAttribute: String, RawRepresentable {
  case Children = "AXChildren"
  case Enabled = "AXEnabled"
  case FocusedWindow = "AXFocusedWindow"
  case MenuBar = "AXMenuBar"
  case MenuItemCmdChar = "AXMenuItemCmdChar"
  case MenuItemCmdGlyph = "AXMenuItemCmdGlyph"
  case MenuItemCmdModifiers = "AXMenuItemCmdModifiers"
  case Role = "AXRole"
  case Subrole = "AXSubrole"
  case Title = "AXTitle"
}


/**
 Error thrown when low-level accessibility API (Carbon) return errors.
 */
struct AXAPIError: LocalizedError {
  let code: AXError

  var errorDescription: String? {
    switch code {
    case .actionUnsupported: return "actionUnsupported"
    case .apiDisabled: return "apiDisabled"
    case .attributeUnsupported: return "attributeUnsupported"
    case .cannotComplete: return "cannotComplete"
    case .failure: return "failure"
    case .illegalArgument: return "illegalArgument"
    case .invalidUIElement: return "invalidUIElement"
    case .invalidUIElementObserver: return "invalidUIElementObserver"
    case .noValue: return "noValue"
    case .notEnoughPrecision: return "notEnoughPrecision"
    case .notificationAlreadyRegistered: return "notificationAlreadyRegistered"
    case .notificationNotRegistered: return "notificationNotRegistered"
    case .notificationUnsupported: return "notificationUnsupported"
    case .parameterizedAttributeUnsupported: return "parameterizedAttributeUnsupported"
    case .success: return "success"
    default: return "unknown"
    }
  }
}


/**
 Accessibility errors thrown by AX framework.
 */
enum AXElementError: Error {
  case attributeNotFound(AX.Attribute)
  case invalidType(String)
}


/**
 Enumeration of known accessibility UI element roles.

 ```sh
 grep -E '^\#define.*Role.*CFSTR' AXRoleConstants.h \
 | sed -E -e 's/^\#define.*kAX[A-Za-z]+Role//' \
 | tr -d '[:blank:]' \
 | sed -E -e 's/^CFSTR\("AX([A-Za-z]+)"\)/case \1 = "AX\1"/' \
 | sort
 ```
 */
enum AXRole: String, RawRepresentable {
  case Application = "AXApplication"
  case Browser = "AXBrowser"
  case BusyIndicator = "AXBusyIndicator"
  case Button = "AXButton"
  case Cell = "AXCell"
  case CheckBox = "AXCheckBox"
  case ColorWell = "AXColorWell"
  case Column = "AXColumn"
  case ComboBox = "AXComboBox"
  case DateField = "AXDateField"
  case DisclosureTriangle = "AXDisclosureTriangle"
  case DockItem = "AXDockItem"
  case Drawer = "AXDrawer"
  case Grid = "AXGrid"
  case Group = "AXGroup"
  case GrowArea = "AXGrowArea"
  case Handle = "AXHandle"
  case HelpTag = "AXHelpTag"
  case Image = "AXImage"
  case Incrementor = "AXIncrementor"
  case LayoutArea = "AXLayoutArea"
  case LayoutItem = "AXLayoutItem"
  case LevelIndicator = "AXLevelIndicator"
  case List = "AXList"
  case Matte = "AXMatte"
  case Menu = "AXMenu"
  case MenuBar = "AXMenuBar"
  case MenuBarItem = "AXMenuBarItem"
  case MenuButton = "AXMenuButton"
  case MenuItem = "AXMenuItem"
  case Outline = "AXOutline"
  case PopUpButton = "AXPopUpButton"
  case Popover = "AXPopover"
  case ProgressIndicator = "AXProgressIndicator"
  case RadioButton = "AXRadioButton"
  case RadioGroup = "AXRadioGroup"
  case RelevanceIndicator = "AXRelevanceIndicator"
  case Row = "AXRow"
  case Ruler = "AXRuler"
  case RulerMarker = "AXRulerMarker"
  case ScrollArea = "AXScrollArea"
  case ScrollBar = "AXScrollBar"
  case Sheet = "AXSheet"
  case Slider = "AXSlider"
  case SplitGroup = "AXSplitGroup"
  case Splitter = "AXSplitter"
  case StaticText = "AXStaticText"
  case SystemWide = "AXSystemWide"
  case TabGroup = "AXTabGroup"
  case Table = "AXTable"
  case TextArea = "AXTextArea"
  case TextField = "AXTextField"
  case TimeField = "AXTimeField"
  case Toolbar = "AXToolbar"
  case Unknown = "AXUnknown"
  case ValueIndicator = "AXValueIndicator"
  case Window = "AXWindow"
}
