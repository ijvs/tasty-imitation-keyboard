//
//  KeyboardLayout.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/25/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

struct layoutConstants {
    static let landscapeRatio: CGFloat = 2
    
    // side edges increase on 6 in portrait
    static let sideEdgesPortraitArray: [CGFloat] = [3, 4]
    static let sideEdgesPortraitWidthThreshholds: [CGFloat] = [700]
    static let sideEdgesLandscape: CGFloat = 3
    
    // top edges decrease on various devices in portrait
    static let topEdgePortraitArray: [CGFloat] = [12, 10, 8]
    static let topEdgePortraitWidthThreshholds: [CGFloat] = [350, 400]
    static let topEdgeLandscape: CGFloat = 6
    
    // keyboard area shrinks in size in landscape on 6 and 6+
    static let keyboardShrunkSizeArray: [CGFloat] = [522, 524]
    static let keyboardShrunkSizeWidthThreshholds: [CGFloat] = [700]
    static let keyboardShrunkSizeBaseWidthThreshhold: CGFloat = 600
    
    // row gaps are weird on 6 in portrait
    static let rowGapPortraitArray: [CGFloat] = [15, 11, 10]
    static let rowGapPortraitThreshholds: [CGFloat] = [350, 400]
    static let rowGapPortraitLastRow: CGFloat = 9
    static let rowGapPortraitLastRowIndex: Int = 1
    static let rowGapLandscape: CGFloat = 7
    
    static let keyGaps: CGFloat = 6
    static let keyGapsSmall: CGFloat = 5
    static let keyGapsSmallThreshhold: CGFloat = 10
    
    static func sideEdgesPortrait(width: CGFloat) -> CGFloat { return self.findThreshhold(self.sideEdgesPortraitArray, threshholds: self.sideEdgesPortraitWidthThreshholds, measurement: width) }
    static func topEdgePortrait(width: CGFloat) -> CGFloat { return self.findThreshhold(self.topEdgePortraitArray, threshholds: self.topEdgePortraitWidthThreshholds, measurement: width) }
    static func rowGapPortrait(width: CGFloat) -> CGFloat { return self.findThreshhold(self.rowGapPortraitArray, threshholds: self.rowGapPortraitThreshholds, measurement: width) }
    
    static func rowGapPortraitLastRow(width: CGFloat) -> CGFloat {
        let index = self.findThreshholdIndex(self.rowGapPortraitThreshholds, measurement: width)
        if index == self.rowGapPortraitLastRowIndex {
            return self.rowGapPortraitLastRow
        }
        else {
            return self.rowGapPortraitArray[index]
        }
    }
    
    static func keyboardShrunkSize(width: CGFloat) -> CGFloat {
        if width >= self.keyboardShrunkSizeBaseWidthThreshhold {
            return self.findThreshhold(self.keyboardShrunkSizeArray, threshholds: self.keyboardShrunkSizeWidthThreshholds, measurement: width)
        }
        else {
            return width
        }
    }
    
    static func findThreshhold(elements: [CGFloat], threshholds: [CGFloat], measurement: CGFloat) -> CGFloat {
        assert(elements.count == threshholds.count + 1, "elements and threshholds do not match")
        return elements[self.findThreshholdIndex(threshholds, measurement: measurement)]
    }
    static func findThreshholdIndex(threshholds: [CGFloat], measurement: CGFloat) -> Int {
        for (i, threshhold) in enumerate(reverse(threshholds)) {
            if measurement >= threshhold {
                let actualIndex = threshholds.count - i
                return actualIndex
            }
        }
        return 0
    }
}

let globalColors: [String:UIColor] = [
    "lightColor": UIColor.whiteColor(),
    "lightShadowColor": UIColor(hue: (220/360.0), saturation: 0.04, brightness: 0.56, alpha: 1),
    "lightTextColor": UIColor.blackColor(),
    "darkColor": UIColor(hue: (217/360.0), saturation: 0.09, brightness: 0.75, alpha: 1),
    "darkShadowColor": UIColor(hue: (220/360.0), saturation: 0.04, brightness: 0.56, alpha: 1),
    "darkTextColor": UIColor.whiteColor(),
    "blueColor": UIColor(hue: (211/360.0), saturation: 1.0, brightness: 1.0, alpha: 1),
    "blueShadowColor": UIColor(hue: (216/360.0), saturation: 0.05, brightness: 0.43, alpha: 1),
    "borderColor": UIColor(hue: (214/360.0), saturation: 0.04, brightness: 0.65, alpha: 1.0)
]

// handles the layout for the keyboard, including key spacing and arrangement
class KeyboardLayout: KeyboardKeyProtocol {
    
    dynamic var colors: [String:UIColor] {
        get {
            return globalColors
        }
    }
    
    var model: Keyboard
    var superview: UIView
    var modelToView: [Key:KeyboardKey] = [:]
    var viewToModel: [KeyboardKey:Key] = [:]
    var elements: [String:UIView] = [:]
    
    var initialized: Bool
    
    var topBanner: CGFloat = 0 {
        didSet {
            self.layoutTemp()
        }
    }
    var topSpacerConstraint: NSLayoutConstraint?
    
    var banner: BannerView?
    
    init(model: Keyboard, superview: UIView, topBanner: CGFloat, banner: BannerView) {
        self.initialized = false
        self.model = model
        self.superview = superview
        self.topBanner = topBanner
        self.banner = banner
        
        self.superview.addSubview(banner)
    }
    
    func initialize() {
        assert(!self.initialized, "already initialized")
        
        self.elements["superview"] = self.superview
        self.createViews(self.model)
        
        self.initialized = true
    }
    
    func viewForKey(model: Key) -> KeyboardKey? {
        return self.modelToView[model]
    }
    
    func keyForView(key: KeyboardKey) -> Key? {
        return self.viewToModel[key]
    }
    
    func setColorsForKey(key: KeyboardKey, model: Key) {
        switch model.type {
        case
        Key.KeyType.Character,
        Key.KeyType.SpecialCharacter,
        Key.KeyType.Period:
            key.color = colors["lightColor"]!
            key.underColor = colors["lightShadowColor"]!
            key.borderColor = colors["borderColor"]!
            key.textColor = colors["lightTextColor"]!
        case
        Key.KeyType.Space:
            key.color = colors["lightColor"]!
            key.underColor = colors["lightShadowColor"]!
            key.borderColor = colors["borderColor"]!
            key.textColor = colors["lightTextColor"]!
            key.downColor = colors["darkColor"]!
        case
        Key.KeyType.Shift,
        Key.KeyType.Backspace:
            key.color = colors["darkColor"]!
            key.underColor = colors["darkShadowColor"]!
            key.borderColor = colors["borderColor"]!
            key.textColor = colors["darkTextColor"]!
            key.downColor = colors["lightColor"]!
            key.downUnderColor = colors["lightShadowColor"]!
            key.downTextColor = colors["lightTextColor"]!
        case
        Key.KeyType.ModeChange:
            key.color = colors["darkColor"]!
            key.underColor = colors["darkShadowColor"]!
            key.borderColor = colors["borderColor"]!
            key.textColor = colors["lightTextColor"]!
        case
        Key.KeyType.Return,
        Key.KeyType.KeyboardChange:
            key.color = colors["darkColor"]!
            key.underColor = colors["darkShadowColor"]!
            key.borderColor = colors["borderColor"]!
            key.textColor = colors["lightTextColor"]!
            key.downColor = colors["lightColor"]!
            key.downUnderColor = colors["lightShadowColor"]!
        }
    }
    
    func createViews(keyboard: Keyboard) {
        for (h, page) in enumerate(keyboard.pages) {
            let numRows = page.rows.count
            
            for i in 0...numRows {
                
                if (i < numRows) {
                    let numKeys = page.rows[i].count
                    
                    for j in 0...numKeys {
                        
                        if (j < numKeys) {
                            var key = page.rows[i][j]
                            
                            var keyView = KeyboardKey(frame: CGRectZero) // TODO:
                            let keyViewName = "key\(j)x\(i)p\(h)"
                            keyView.enabled = true
                            keyView.text = key.keyCapForCase(false)
                            keyView.delegate = self
                            
                            self.superview.addSubview(keyView)
                            
                            self.elements[keyViewName] = keyView
                            self.modelToView[key] = keyView
                            self.viewToModel[keyView] = key
                            
                            setColorsForKey(keyView, model: key)
                            
                            // font sizing
                            switch key.type {
                            case
                            Key.KeyType.ModeChange,
                            Key.KeyType.Space,
                            Key.KeyType.Return:
                                keyView.keyView.label.adjustsFontSizeToFitWidth = false
                                keyView.keyView.label.minimumScaleFactor = 0.1
                                keyView.keyView.label.font = keyView.keyView.label.font.fontWithSize(16)
                            default:
                                break
                            }
                            
                            // shapes
                            switch key.type {
                            case Key.KeyType.Shift:
                                let shiftShape = ShiftShape()
                                keyView.shape = shiftShape
                            case Key.KeyType.Backspace:
                                let backspaceShape = BackspaceShape()
                                keyView.shape = backspaceShape
                            case Key.KeyType.KeyboardChange:
                                let globeShape = GlobeShape()
                                keyView.shape = globeShape
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
    }
    
    //////////////////////
    // LAYOUT FUNCTIONS //
    //////////////////////
    
    // TODO: temp
    func layoutTemp() {
        self.layoutKeys(self.model, views: self.modelToView, bounds: self.superview.bounds)
    }
    
    func layoutKeys(model: Keyboard, views: [Key:KeyboardKey], bounds: CGRect) {
        let isLandscape: Bool = {
            let boundsRatio = bounds.width / bounds.height
            return (boundsRatio >= layoutConstants.landscapeRatio)
        }()
        
        self.banner?.frame = CGRectMake(0, 0, self.superview.bounds.width, self.topBanner)
        
        for page in model.pages {
            let numRows = page.rows.count
            
            let mostKeysInRow: Int = {
                var currentMax: Int = 0
                for (i, row) in enumerate(page.rows) {
                    currentMax = max(currentMax, row.count)
                }
                return currentMax
            }()
            
            // measurement
            var sideEdges = (isLandscape ? layoutConstants.sideEdgesPortrait(bounds.width) : layoutConstants.sideEdgesLandscape)
            
            // measurement
            let bottomEdge = sideEdges
            
            let normalKeyboardSize = bounds.width - CGFloat(2) * sideEdges
            
            // measurement
            let shrunkKeyboardSize = layoutConstants.keyboardShrunkSize(normalKeyboardSize)
            
            sideEdges += ((normalKeyboardSize - shrunkKeyboardSize) / CGFloat(2))

            // measurement
            let topEdge: CGFloat = ((isLandscape ? layoutConstants.topEdgeLandscape : layoutConstants.topEdgePortrait(bounds.width)) + self.topBanner)
            
            // measurement
            let rowGap: CGFloat = (isLandscape ? layoutConstants.rowGapLandscape : layoutConstants.rowGapPortrait(bounds.width))
            let lastRowGap: CGFloat = (isLandscape ? rowGap : layoutConstants.rowGapPortraitLastRow(bounds.width))
            let rowGapTotal = CGFloat(numRows - 1 - 1) * rowGap + lastRowGap
            
            // measurement
            let keyGaps: CGFloat = {
                let pastThreshhold = (CGFloat(mostKeysInRow) >= layoutConstants.keyGapsSmallThreshhold)
                return (pastThreshhold ? layoutConstants.keyGapsSmall : layoutConstants.keyGaps)
            }()
            
            // measurement
            let keyHeight: CGFloat = {
                let totalGaps = bottomEdge + topEdge + rowGapTotal
                return (bounds.height - totalGaps) / CGFloat(numRows)
            }()
            
            // measurement
            let letterKeyWidth: CGFloat = {
                let totalGaps = (sideEdges * CGFloat(2)) + (keyGaps * CGFloat(mostKeysInRow - 1))
                return (bounds.width - totalGaps) / CGFloat(mostKeysInRow)
            }()
            
            for (r, row) in enumerate(page.rows) {
                let rowGapCurrentTotal = (r == page.rows.count - 1 ? rowGapTotal : CGFloat(r) * rowGap)
                let frame = CGRectMake(sideEdges, topEdge + (CGFloat(r) * keyHeight) + rowGapCurrentTotal, bounds.width - CGFloat(2) * sideEdges, keyHeight)
                self.handleRow(row, keyGaps: keyGaps, letterKeyWidth: letterKeyWidth, frame: frame)
            }
        }
    }
    
    // quick heuristics for default keyboard rows
    // feel free to extend this method (calling super) with your own row layouts
    func handleRow(row: [Key], keyGaps: CGFloat, letterKeyWidth: CGFloat, frame: CGRect) {
        
        // basic character row: only typable characters
        if row[0].type == Key.KeyType.Character {
            self.layoutCharacterRow(row, modelToView: self.modelToView, keyWidth: letterKeyWidth, gapWidth: keyGaps, frame: frame)
        }
            
        // character row with side buttons: shift, backspace, etc.
        else if row[1].type == Key.KeyType.Character {
            self.layoutCharacterWithSidesRow(row, modelToView: self.modelToView, keyWidth: letterKeyWidth, gapWidth: keyGaps, otherKeyRatio: CGFloat(0.75), frame: frame)
        }
            
        // bottom row with things like space, return, etc.
        else {
            self.layoutSpecialKeysRow(row, modelToView: self.modelToView, gapWidth: keyGaps, leftSideRatio: CGFloat(0.25), spaceRatio: CGFloat(0.5), frame: frame)
        }
    }
    
    func layoutCharacterRow(row: [Key], modelToView: [Key:KeyboardKey], keyWidth: CGFloat, gapWidth: CGFloat, frame: CGRect) {
        let keySpace = CGFloat(row.count) * keyWidth + CGFloat(row.count - 1) * gapWidth
        let sideSpace = (frame.width - keySpace) / CGFloat(2)
        
        var currentOrigin = frame.origin.x + sideSpace
        for (k, key) in enumerate(row) {
            if let view = modelToView[key] {
                view.frame = CGRectMake(currentOrigin, frame.origin.y, keyWidth, frame.height)
                currentOrigin += (keyWidth + gapWidth)
            }
            else {
                assert(false, "view missing for model")
            }
        }
    }
    
    func layoutCharacterWithSidesRow(row: [Key], modelToView: [Key:KeyboardKey], keyWidth: CGFloat, gapWidth: CGFloat, otherKeyRatio: CGFloat, frame: CGRect) {
        let numCharacters = row.count - 2
        let keySpace = CGFloat(numCharacters) * keyWidth + CGFloat(numCharacters - 1) * gapWidth
        let sideSpace = (frame.width - keySpace) / CGFloat(2)
        let specialCharacterWidth = sideSpace * otherKeyRatio
        let specialCharacterGap = sideSpace - specialCharacterWidth
        
        var currentOrigin = frame.origin.x
        for (k, key) in enumerate(row) {
            if let view = modelToView[key] {
                if k == 0 {
                    view.frame = CGRectMake(currentOrigin, frame.origin.y, specialCharacterWidth, frame.height)
                    currentOrigin += (specialCharacterWidth + specialCharacterGap)
                }
                else if k == row.count - 1 {
                    currentOrigin += specialCharacterGap
                    view.frame = CGRectMake(currentOrigin, frame.origin.y, specialCharacterWidth, frame.height)
                    currentOrigin += specialCharacterWidth
                }
                else {
                    view.frame = CGRectMake(currentOrigin, frame.origin.y, keyWidth, frame.height)
                    if k == row.count - 2 {
                        currentOrigin += (keyWidth)
                    }
                    else {
                        currentOrigin += (keyWidth + gapWidth)
                    }
                }
            }
            else {
                assert(false, "view missing for model")
            }
        }
    }
    
    func layoutSpecialKeysRow(row: [Key], modelToView: [Key:KeyboardKey], gapWidth: CGFloat, leftSideRatio: CGFloat, spaceRatio: CGFloat, frame: CGRect) {
        assert(row.count == 4, "no support for more than 4 keys on bottom row yet")
        
        let keyCount = row.count
        let leftSideWidth = (frame.width * leftSideRatio)
        let leftSideIndividualKeyWidth = (leftSideWidth - gapWidth) / CGFloat(2)
        let spaceWidth = (frame.width * spaceRatio)
        let otherKeyWidth = (frame.width - leftSideWidth - spaceWidth - gapWidth * CGFloat(2))
        
        var currentOrigin = frame.origin.x
        var beforeSpace: Bool = true
        for (k, key) in enumerate(row) {
            if let view = modelToView[key] {
                if key.type == Key.KeyType.Space {
                    view.frame = CGRectMake(currentOrigin, frame.origin.y, spaceWidth, frame.height)
                    currentOrigin += (spaceWidth + gapWidth)
                    beforeSpace = false
                }
                else if beforeSpace {
                    view.frame = CGRectMake(currentOrigin, frame.origin.y, leftSideIndividualKeyWidth, frame.height)
                    currentOrigin += (leftSideIndividualKeyWidth + gapWidth)
                }
                else {
                    view.frame = CGRectMake(currentOrigin, frame.origin.y, otherKeyWidth, frame.height)
                    currentOrigin += (otherKeyWidth + gapWidth)
                }
            }
            else {
                assert(false, "view missing for model")
            }
        }
    }
    
    ////////////////
    // END LAYOUT //
    ////////////////
    
    // TODO: superview constraints not part of allConstraints array, and also allConstraints does not work recursively
//    var extraConstraints: [(UIView, [NSLayoutConstraint])] = []
    func willShowPopup(key: KeyboardKey, direction: Direction) {
//        if let popup = key.popup {
//            let directionToAttribute = [
//                Direction.Up: NSLayoutAttribute.Top,
//                Direction.Down: NSLayoutAttribute.Bottom,
//                Direction.Left: NSLayoutAttribute.Left,
//                Direction.Right: NSLayoutAttribute.Right,
//            ]
//            
//            for (view, constraintArray) in self.extraConstraints {
//                if key == view {
//                    for constraint in constraintArray {
//                        self.superview.removeConstraint(constraint)
//                    }
//                }
//            }
//            
//            var extraConstraints: [NSLayoutConstraint] = []
//            
//            var cantTouchTopConstraint = NSLayoutConstraint(
//                item: popup,
//                attribute: directionToAttribute[direction]!,
//                relatedBy: (direction == Direction.Right ? NSLayoutRelation.LessThanOrEqual : NSLayoutRelation.GreaterThanOrEqual),
//                toItem: self.superview,
//                attribute: directionToAttribute[direction]!,
//                multiplier: 1,
//                constant: 2) // TODO: layout
//            cantTouchTopConstraint.priority = 1000
//            self.superview.addConstraint(cantTouchTopConstraint)
//            extraConstraints.append(cantTouchTopConstraint)
////            self.allConstraintObjects.append(cantTouchTopConstraint)
//            
//            if direction.horizontal() {
//                var cantTouchTopConstraint = NSLayoutConstraint(
//                    item: popup,
//                    attribute: directionToAttribute[Direction.Up]!,
//                    relatedBy: NSLayoutRelation.GreaterThanOrEqual,
//                    toItem: self.superview,
//                    attribute: directionToAttribute[Direction.Up]!,
//                    multiplier: 1,
//                    constant: 5) // TODO: layout
//                cantTouchTopConstraint.priority = 1000
//                self.superview.addConstraint(cantTouchTopConstraint)
//                extraConstraints.append(cantTouchTopConstraint)
////                self.allConstraintObjects.append(cantTouchTopConstraint)
//            }
//            else {
//                var cantTouchSideConstraint = NSLayoutConstraint(
//                    item: self.superview,
//                    attribute: directionToAttribute[Direction.Right]!,
//                    relatedBy: NSLayoutRelation.GreaterThanOrEqual,
//                    toItem: popup,
//                    attribute: directionToAttribute[Direction.Right]!,
//                    multiplier: 1,
//                    constant: 3) // TODO: layout
//                cantTouchSideConstraint.priority = 1000
//                var cantTouchSideConstraint2 = NSLayoutConstraint(
//                    item: self.superview,
//                    attribute: directionToAttribute[Direction.Left]!,
//                    relatedBy: NSLayoutRelation.LessThanOrEqual,
//                    toItem: popup,
//                    attribute: directionToAttribute[Direction.Left]!,
//                    multiplier: 1,
//                    constant: -3) // TODO: layout
//                cantTouchSideConstraint2.priority = 1000
//                
//                self.superview.addConstraint(cantTouchSideConstraint)
//                self.superview.addConstraint(cantTouchSideConstraint2)
//                extraConstraints.append(cantTouchSideConstraint)
//                extraConstraints.append(cantTouchSideConstraint2)
////                self.allConstraintObjects.append(cantTouchSideConstraint)
////                self.allConstraintObjects.append(cantTouchSideConstraint2)
//            }
//            
//            self.extraConstraints.append((key, extraConstraints) as (UIView, [NSLayoutConstraint]))
//        }
    }
    
    func willHidePopup(key: KeyboardKey) {
//        for (view, constraintArray) in self.extraConstraints {
//            if key == view {
//                for constraint in constraintArray {
//                    self.superview.removeConstraint(constraint)
//                }
//            }
//        }
    }
}