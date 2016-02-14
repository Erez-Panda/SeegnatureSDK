//
//  File.swift
//  Panda4doctor
//
//  Created by Erez Haim on 2/5/15.
//  Copyright (c) 2015 Erez. All rights reserved.
//

struct TimeUtils {
    
    static func serverDateTimeStrToDate(dateTime: String) -> NSDate{
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(abbreviation: "UTC");
        dateFormatter.dateFormat = NSDateFormatter.dateFormatFromTemplate("yyyy-MM-dd'T'HH:mm:ss", options: 0, locale: nil)
        var date = dateFormatter.dateFromString(dateTime)
        if date == nil {
            var str = dateTime.stringByReplacingOccurrencesOfString("T", withString: " ")
            str = str.stringByReplacingOccurrencesOfString("Z", withString: "")
            str = str.stringByPaddingToLength(19, withString: "", startingAtIndex: 0)
            date = dateFormatter.dateFromString(str)
        }
        return date!
    }
    
    static func dateToReadableStr(date: NSDate) -> String{
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone();
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        let readableTime = dateFormatter.stringFromDate(date)
        return readableTime
    }
    
    static func dateToDateStr(date: NSDate) -> String{
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone();
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        let readableTime = dateFormatter.stringFromDate(date)
        return readableTime
    }

    
    static func dateToTimeStr(date: NSDate) -> String{
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone();
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        let readableTime = dateFormatter.stringFromDate(date)
        return readableTime
    }
    
    static func dateToServerString(date:NSDate) -> String{
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US")
        dateFormatter.timeZone = NSTimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = NSDateFormatter.dateFormatFromTemplate("yyyy-MM-dd'T'HH:mm:ss", options: 0, locale: nil)
        let stringDate = dateFormatter.stringFromDate(date)
        return stringDate
    }
    
    static func getOffsetFromUTC() -> Int{
        let minutes = NSTimeZone.localTimeZone().secondsFromGMT / 60
        return minutes/60
    }
    
    
    static func getDateWithTime(date: NSDate, hour: Int?, minute: Int?)-> NSDate{
        let cal = NSCalendar(calendarIdentifier:NSCalendarIdentifierGregorian)!
        let comp = cal.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: date)
        if let h = hour{
            comp.hour = h
        }
        if let m = minute {
            comp.minute = m
        }
        return cal.dateFromComponents(comp)!
    }
}

