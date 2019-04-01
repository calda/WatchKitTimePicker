//
//  TimePickerDataSource.swift
//  WatchKitTimePicker
//
//  Created by Cal Stephens on 11/5/18.
//  Copyright © 2018 Cal Stephens. All rights reserved.
//

import WatchKit

public class TimePickerDataSource {
    
    private weak var hoursPicker: WKInterfacePicker?
    private weak var minutesPicker: WKInterfacePicker?
    private weak var amPmPicker: WKInterfacePicker?
    
    private let interval: SelectionInterval
    public var selectedTimeDidUpdate: ((Date) -> Void)?
    
    public enum SelectionInterval {
        case minute
        case fiveMinutes
        case fifteenMinutes
        case halfHour
        
        var minutesBetweenOptions: Int {
            switch self {
            case .minute: return 1
            case .fiveMinutes: return 5
            case .fifteenMinutes: return 15
            case .halfHour: return 30
            }
        }
    }
    
    public init(
        hoursPicker: WKInterfacePicker,
        minutesPicker: WKInterfacePicker,
        amPmPicker: WKInterfacePicker?,
        interval: SelectionInterval = .fiveMinutes)
    {
        self.interval = interval
        self.hoursPicker = hoursPicker
        self.minutesPicker = minutesPicker
        self.amPmPicker = amPmPicker
    }
    
    
    // MARK: Setup
    
    private lazy var userHas24HourTimeEnabled: Bool = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        
        let timeString = timeFormatter.string(from: Date())
        return !(timeString.contains(Locale.current.calendar.amSymbol)
              || timeString.contains(Locale.current.calendar.pmSymbol))
    }()
    
    private lazy var hourPickerOptions: [Int] = {
        if userHas24HourTimeEnabled {
            return Array(0...23)
        } else {
            return [/* am: */ 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
                    /* pm: */ 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
        }
    }()
    
    /// 0-60 minute entries for all 24 hours in the day.
    private lazy var minutePickerOptions: [Int] = { (interval: SelectionInterval) in
        Array(repeating: Array(stride(from: 0, to: 60, by: interval.minutesBetweenOptions)), count: 24).flatMap { $0 }
    }(self.interval)
    
    private lazy var amPmPickerOptions: [String]? = {
        if userHas24HourTimeEnabled {
            return nil
        } else {
            return [
                Locale.current.calendar.amSymbol,
                Locale.current.calendar.pmSymbol]
        }
    }()
    
    public func setup(withInitiallySelectedDate initiallySelectedDate: Date?) {
        hoursPicker?.setItems(hourPickerOptions.map { hourValue in
            let pickerItem = WKPickerItem()
            pickerItem.title = "\(hourValue)"
            return pickerItem
        })
        
        minutesPicker?.setItems(minutePickerOptions.map { minuteValue in
            let pickerItem = WKPickerItem()
            if "\(minuteValue)".count == 1 {
                pickerItem.title = "0\(minuteValue)"
            } else {
                pickerItem.title = "\(minuteValue)"
            }
            return pickerItem
        })
        
        if let amPmPickerOptions = amPmPickerOptions {
            amPmPicker?.setItems(amPmPickerOptions.map { value in
                let pickerItem = WKPickerItem()
                pickerItem.title = value
                return pickerItem
            })
            
            amPmPicker?.setHidden(false)
            hoursPicker?.setRelativeWidth(0.333, withAdjustment: 0)
            minutesPicker?.setRelativeWidth(0.333, withAdjustment: 0)
            amPmPicker?.setRelativeWidth(0.333, withAdjustment: 0)
            
        } else {
            amPmPicker?.setHidden(true)
            hoursPicker?.setRelativeWidth(0.5, withAdjustment: 0)
            minutesPicker?.setRelativeWidth(0.5, withAdjustment: 0)
        }
        
        // set the initial values of the pickers
        if let initiallySelectedDate = initiallySelectedDate {
            let dateComponents = Calendar.current.dateComponents(Set(arrayLiteral: .hour, .minute), from: initiallySelectedDate)
            let hours = dateComponents.hour!
            let minutes = dateComponents.minute!
            
            hoursPicker?.setSelectedItemIndex(hours)
            selectedHour = hourPickerOptions[hours]
            
            let displayedMinutesPerHour = minutePickerOptions.count / 24
            let corresponsingMinuteIndex = (minutePickerOptions.firstIndex(where: { $0 >= minutes }) ?? 0) + (displayedMinutesPerHour * hours)
            minutesPicker?.setSelectedItemIndex(corresponsingMinuteIndex)
            selectedMinute = minutePickerOptions[corresponsingMinuteIndex]
            
            if userHas24HourTimeEnabled {
                amPm = nil
            } else {
                if hours < 12 {
                    amPmPicker?.setSelectedItemIndex(0)
                    amPm = .am
                } else {
                    amPmPicker?.setSelectedItemIndex(1)
                    amPm = .pm
                }
            }
        }
    }
    
    
    // MARK: User Interaction
    
    private enum AMPM {
        case am, pm
    }
    
    private var selectedHour: Int = 0
    private var selectedMinute: Int = 0
    private var amPm: AMPM? = .am
    
    public func hourPickerUpdated(to index: Int) {
        selectedHour = hourPickerOptions[index]
        
        // if using 12-hour time, switching between the first half and the last half swaps between AM and PM
        if !userHas24HourTimeEnabled {
            let selectedHourIsInTheAM = (index < 12)
            
            if selectedHourIsInTheAM, amPm == .pm {
                amPmPicker?.setSelectedItemIndex(0)
            }
                
            else if !selectedHourIsInTheAM, amPm == .am {
                amPmPicker?.setSelectedItemIndex(1)
            }
        }
        
        // there are minute values for each of the 24 hours in the day,
        // so make sure the selected minute corresponds with the selected hour
        let displayedMinutesPerHour = minutePickerOptions.count / 24
        let corresponsingMinuteIndex = (minutePickerOptions.firstIndex(of: selectedMinute) ?? 0) + (displayedMinutesPerHour * index)
        minutesPicker?.setSelectedItemIndex(corresponsingMinuteIndex)
        
        selectedTimeDidUpdate?(selectedTime())
    }
    
    public func minutePickerUpdated(to index: Int) {
        selectedMinute = minutePickerOptions[index]
        
        // there are minute values for each of the 24 hours in the day,
        // so make sure the selected hour corresponds with the selected minute
        let displayedMinutesPerHour = minutePickerOptions.count / 24
        let expectedHourIndex = index / (displayedMinutesPerHour)
        let expectedHour = hourPickerOptions[expectedHourIndex]
        if selectedHour != expectedHour {
            hoursPicker?.setSelectedItemIndex(expectedHourIndex)
        }
        
        selectedTimeDidUpdate?(selectedTime())
    }
    
    public func amPmPickerUpdated(to index: Int) {
        guard !userHas24HourTimeEnabled else { return }
        
        if index == 0 { amPm = .am }
        else { amPm = .pm }
        
        // update the hour picker to inhabit the correct half of the 24 picker options
        var selectedIndex = hourPickerOptions.firstIndex(of: selectedHour) ?? 0
        if amPm == .pm {
            // the PM times inhabit the second half
            selectedIndex += 12
        }
        
        hoursPicker?.setSelectedItemIndex(selectedIndex)
        hourPickerUpdated(to: selectedIndex)
        
        selectedTimeDidUpdate?(selectedTime())
    }
    
    public func selectedTime() -> Date {
        var hourIn24HourTime = selectedHour
        
        // if there's an option for am/pm, the user's in 12 hour time.
        // Need to do the necessary corrections.
        if let amPm = amPm {
            if hourIn24HourTime == 12 && amPm == .am {
                hourIn24HourTime = 0
            } else if hourIn24HourTime == 12 && amPm == .pm {
                hourIn24HourTime = 12
            } else if amPm == .pm {
                hourIn24HourTime += 12
            }
        }
        
        return Calendar.current.date(
            bySettingHour: hourIn24HourTime,
            minute: selectedMinute,
            second: 0,
            of: Date(),
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward)!
    }
    
}
