//
//  AX.swift
//  MenuFinder
//
//  Created by Jesse Kasky on 6/29/16.
//  Copyright © 2016 Codjax. All rights reserved.
//

import Carbon
import Foundation


enum AX {
  typealias Action = AXActionEnum
  typealias Attribute = AXAttributeEnum
  typealias APIError = AXAPIError
  typealias Error = AXErrorEnum
  typealias Role = AXRoleEnum
}


/**
 * Enumeration of known accessibility UI element actions.
 *
 * Swift enum values must be primitive so the CFSTR values defined in
 * AXActionConstants.h. The enum vales below were generated with the following
 * script.
 *
 * grep '^\#define.*Action.*CFSTR' AXActionConstants.h \
 * | sed -E -e 's/^\#define kAX[A-Za-z]+Action//' \
 * | tr -d '[:blank:]' \
 * | sed -E -e 's/^CFSTR\("AX([A-Za-z]+)"\)/case \1 = "AX\1"/' \
 * | sort
 */
enum AXActionEnum: String, RawRepresentable {
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
 * Enumeration of known accessibility UI element attribute names.
 *
 * Swift enum values must be primitive so the CFSTR values defined in
 * AXAttributeConstants.h. The enum vales below were generated with the following
 * script.
 *
 * grep '^\#define.*Attribute.*CFSTR' AXAttributeConstants.h \
 * | sed -E -e 's/^\#define kAX[A-Za-z]+Attribute//' \
 * | tr -d '[:blank:]' \
 * | sed -E -e 's/^CFSTR\("AX([A-Za-z]+)"\)/case \1 = "AX\1"/' \
 * | sort
 */
enum AXAttributeEnum: String, RawRepresentable {
  case AMPMField = "AXAMPMField"
  case AllowedValues = "AXAllowedValues"
  case AlternateUIVisible = "AXAlternateUIVisible"
  case AttributedStringForRange = "AXAttributedStringForRange"
  case BoundsForRange = "AXBoundsForRange"
  case CancelButton = "AXCancelButton"
  case CellForColumnAndRow = "AXCellForColumnAndRow"
  case Children = "AXChildren"
  case ClearButton = "AXClearButton"
  case CloseButton = "AXCloseButton"
  case ColumnCount = "AXColumnCount"
  case ColumnHeaderUIElements = "AXColumnHeaderUIElements"
  case ColumnIndexRange = "AXColumnIndexRange"
  case ColumnTitles = "AXColumnTitles"
  case Columns = "AXColumns"
  case Contents = "AXContents"
  case CriticalValue = "AXCriticalValue"
  case DayField = "AXDayField"
  case DecrementButton = "AXDecrementButton"
  case DefaultButton = "AXDefaultButton"
  case Description = "AXDescription"
  case DisclosedByRow = "AXDisclosedByRow"
  case DisclosedRows = "AXDisclosedRows"
  case Disclosing = "AXDisclosing"
  case DisclosureLevel = "AXDisclosureLevel"
  case Document = "AXDocument"
  case Edited = "AXEdited"
  case ElementBusy = "AXElementBusy"
  case Enabled = "AXEnabled"
  case Expanded = "AXExpanded"
  case ExtrasMenuBar = "AXExtrasMenuBar"
  case Filename = "AXFilename"
  case Focused = "AXFocused"
  case FocusedApplication = "AXFocusedApplication"
  case FocusedUIElement = "AXFocusedUIElement"
  case FocusedWindow = "AXFocusedWindow"
  case Frontmost = "AXFrontmost"
  case FullScreenButton = "AXFullScreenButton"
  case GrowArea = "AXGrowArea"
  case Handles = "AXHandles"
  case Header = "AXHeader"
  case Help = "AXHelp"
  case Hidden = "AXHidden"
  case HorizontalScrollBar = "AXHorizontalScrollBar"
  case HorizontalUnitDescription = "AXHorizontalUnitDescription"
  case HorizontalUnits = "AXHorizontalUnits"
  case HourField = "AXHourField"
  case Identifier = "AXIdentifier"
  case IncrementButton = "AXIncrementButton"
  case Incrementor = "AXIncrementor"
  case Index = "AXIndex"
  case InsertionPointLineNumber = "AXInsertionPointLineNumber"
  case IsApplicationRunning = "AXIsApplicationRunning"
  case IsEditable = "AXIsEditable"
  case LabelUIElements = "AXLabelUIElements"
  case LabelValue = "AXLabelValue"
  case LayoutPointForScreenPoint = "AXLayoutPointForScreenPoint"
  case LayoutSizeForScreenSize = "AXLayoutSizeForScreenSize"
  case LineForIndex = "AXLineForIndex"
  case LinkedUIElements = "AXLinkedUIElements"
  case Main = "AXMain"
  case MainWindow = "AXMainWindow"
  case MarkerType = "AXMarkerType"
  case MarkerTypeDescription = "AXMarkerTypeDescription"
  case MarkerUIElements = "AXMarkerUIElements"
  case MatteContentUIElement = "AXMatteContentUIElement"
  case MatteHole = "AXMatteHole"
  case MaxValue = "AXMaxValue"
  case MenuBar = "AXMenuBar"
  case MenuItemCmdChar = "AXMenuItemCmdChar"
  case MenuItemCmdGlyph = "AXMenuItemCmdGlyph"
  case MenuItemCmdModifiers = "AXMenuItemCmdModifiers"
  case MenuItemCmdVirtualKey = "AXMenuItemCmdVirtualKey"
  case MenuItemMarkChar = "AXMenuItemMarkChar"
  case MenuItemPrimaryUIElement = "AXMenuItemPrimaryUIElement"
  case MinValue = "AXMinValue"
  case MinimizeButton = "AXMinimizeButton"
  case Minimized = "AXMinimized"
  case MinuteField = "AXMinuteField"
  case Modal = "AXModal"
  case MonthField = "AXMonthField"
  case NextContents = "AXNextContents"
  case NumberOfCharacters = "AXNumberOfCharacters"
  case OrderedByRow = "AXOrderedByRow"
  case Orientation = "AXOrientation"
  case OverflowButton = "AXOverflowButton"
  case Parent = "AXParent"
  case PlaceholderValue = "AXPlaceholderValue"
  case Position = "AXPosition"
  case PreviousContents = "AXPreviousContents"
  case Proxy = "AXProxy"
  case RTFForRange = "AXRTFForRange"
  case RangeForIndex = "AXRangeForIndex"
  case RangeForLine = "AXRangeForLine"
  case RangeForPosition = "AXRangeForPosition"
  case Role = "AXRole"
  case RoleDescription = "AXRoleDescription"
  case RowCount = "AXRowCount"
  case RowHeaderUIElements = "AXRowHeaderUIElements"
  case RowIndexRange = "AXRowIndexRange"
  case Rows = "AXRows"
  case ScreenPointForLayoutPoint = "AXScreenPointForLayoutPoint"
  case ScreenSizeForLayoutSize = "AXScreenSizeForLayoutSize"
  case SearchButton = "AXSearchButton"
  case SecondField = "AXSecondField"
  case Selected = "AXSelected"
  case SelectedCells = "AXSelectedCells"
  case SelectedChildren = "AXSelectedChildren"
  case SelectedColumns = "AXSelectedColumns"
  case SelectedRows = "AXSelectedRows"
  case SelectedText = "AXSelectedText"
  case SelectedTextRange = "AXSelectedTextRange"
  case SelectedTextRanges = "AXSelectedTextRanges"
  case ServesAsTitleForUIElements = "AXServesAsTitleForUIElements"
  case SharedCharacterRange = "AXSharedCharacterRange"
  case SharedFocusElements = "AXSharedFocusElements"
  case SharedTextUIElements = "AXSharedTextUIElements"
  case ShownMenuUIElement = "AXShownMenuUIElement"
  case Size = "AXSize"
  case SortDirection = "AXSortDirection"
  case Splitters = "AXSplitters"
  case StringForRange = "AXStringForRange"
  case StyleRangeForIndex = "AXStyleRangeForIndex"
  case Subrole = "AXSubrole"
  case Tabs = "AXTabs"
  case Text = "AXText"
  case Title = "AXTitle"
  case TitleUIElement = "AXTitleUIElement"
  case ToolbarButton = "AXToolbarButton"
  case TopLevelUIElement = "AXTopLevelUIElement"
  case URL = "AXURL"
  case UnitDescription = "AXUnitDescription"
  case Units = "AXUnits"
  case Value = "AXValue"
  case ValueDescription = "AXValueDescription"
  case ValueIncrement = "AXValueIncrement"
  case ValueWraps = "AXValueWraps"
  case VerticalScrollBar = "AXVerticalScrollBar"
  case VerticalUnitDescription = "AXVerticalUnitDescription"
  case VerticalUnits = "AXVerticalUnits"
  case VisibleCells = "AXVisibleCells"
  case VisibleCharacterRange = "AXVisibleCharacterRange"
  case VisibleChildren = "AXVisibleChildren"
  case VisibleColumns = "AXVisibleColumns"
  case VisibleRows = "AXVisibleRows"
  case VisibleText = "AXVisibleText"
  case WarningValue = "AXWarningValue"
  case Window = "AXWindow"
  case Windows = "AXWindows"
  case YearField = "AXYearField"
  case ZoomButton = "AXZoomButton"
}


/**
 * Error thrown when low-level accessibility API (Carbon) return errors.
 */
class AXAPIError: Error {
  
  let code: AXError
  
  init(code: AXError) {
    self.code = code
  }
}


/**
 * Accessibility errors thrown by AX framework.
 */
enum AXErrorEnum: Error {
  case attributeNotFound(AX.Attribute)
  case invalidType(String)
}


/**
 * Enumeration of known accessibility UI element roles.
 *
 * grep -E '^\#define.*Role.*CFSTR' AXRoleConstants.h \
 * | sed -E -e 's/^\#define.*kAX[A-Za-z]+Role//' \
 * | tr -d '[:blank:]' \
 * | sed -E -e 's/^CFSTR\("AX([A-Za-z]+)"\)/case \1 = "AX\1"/' \
 * | sort
 */
enum AXRoleEnum: String, RawRepresentable {
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
