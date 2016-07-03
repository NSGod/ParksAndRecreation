//
//  IntegralRect.swift
//
//  Created by Zachary Waldowski on 6/26/15.
//  Copyright (c) 2015 Zachary Waldowski. Some rights reserved. Licensed under MIT.
//

import UIKit

private func roundUp(_ value: CGFloat) -> CGFloat {
    return floor(value + 0.5)
}

private extension CGFloat {

    func rounded(to scale: CGFloat, by adjustment: @noescape(CGFloat) throws -> CGFloat) rethrows -> CGFloat {
        guard scale > 1 else {
            return try adjustment(self)
        }
        return try adjustment(self * scale) / scale
    }

}

extension CGRect {

    public func integralizeOutward(_ scale: CGFloat = UIScreen.main().scale) -> CGRect {
        var integralRect = CGRect.zero
        integralRect.origin.x    = minX.rounded(to: scale, by: roundUp)
        integralRect.size.width  = max(width.rounded(to: scale, by: ceil), 0)
        integralRect.origin.y    = minY.rounded(to: scale, by: roundUp)
        integralRect.size.height = max(height.rounded(to: scale, by: ceil), 0)
        return integralRect
    }
    
}
