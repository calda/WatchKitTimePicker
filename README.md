# WatchKitTimePicker

**WatchKitTimePicker** is a time picker data source for WatchKit that...
 - Mirrors the behavior of UIKit's `UIDatePicker`
 - Automatically uses either 12-hour or 24-hour time, depending on the user's current Locale.
 - Supports watchOS 2.0+
 
## Demo
 
<p align="center">
    <img src="images/watchkit time picker 12hr.gif" width="300px">  <img src="images/watchkit time picker 24hr.gif" width="300px">
</p>

<br>


## Installation

#### Manual Installation:

**WatchKitTimePicker** is just one individual .swift file: [`TimePickerDataSource.swift`](https://github.com/calda/WatchKitTimePicker/blob/master/WatchKitTimePicker/TimePickerDataSource.swift). You could install it quickly by downloading that file and dragging it in to your Watch App Extension target.

#### [Carthage](https://github.com/Carthage/Carthage):

Add `github "calda/WatchKitTimePicker"` to your Cartfile.

## Usage

Unlike with iOS view-layer libraries, you can't just distribute and use a `UIView` or `WKInterfaceObject` subclass. Interface elements have to be set up using Interface Builder.

**WatchKitTimePicker** is a data source that controls and manages a group of `WKInterfacePicker` objects. 

### Interface Builder:

- Create a horizontal `WKInterfaceGroup`.
- Add three `WKInterfacePicker` objects to the group.
- Connect and `@IBOutlet` and an `@IBAction` for each of the pickers.

### Your `WKInterfaceController` subclass:

```Swift
import WatchKit
import Foundation
import WatchKitTimePicker

class InterfaceController: WKInterfaceController {

    var timePickerDataSource: TimePickerDataSource!
    @IBOutlet weak var hourTimePicker: WKInterfacePicker!
    @IBOutlet weak var minuteTimePicker: WKInterfacePicker!
    @IBOutlet weak var amPmTimePicker: WKInterfacePicker!
    
    override func awake(withContext context: Any?) {
        timePickerDataSource = TimePickerDataSource(
            hoursPicker: hourTimePicker,
            minutesPicker: minuteTimePicker,
            amPmPicker: amPmTimePicker,
            interval: .fiveMinutes) // supports .minute, .fiveMinutes, .fifteenMinutes, and .halfHour
        
        timePickerDataSource.selectedTimeDidUpdate = { selectedTime in
            // ...
        }
        
        timePickerDataSource.setup(withInitiallySelectedDate: Date())
    }
    
    @IBAction func hourPickerDidUpdate(_ index: Int) {
        timePickerDataSource.hourPickerUpdated(to: index)
    }
    
    @IBAction func minutePickerDidUpdate(_ index: Int) {
        timePickerDataSource.minutePickerUpdated(to: index)
    }
    
    @IBAction func amPmPickerDidUpdate(_ index: Int) {
        timePickerDataSource.amPmPickerUpdated(to: index)
    }
    
}

```
