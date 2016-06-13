//
//  PDFAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 3/7/16.
//
//

import UIKit

protocol PDFAnnotation {
    
    func drawInContext(_ context: CGContext)
}

struct PDFTextAnnotation:PDFAnnotation {
    
    var text:String = ""
    var rect:CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    var font:UIFont = UIFont.systemFont(ofSize: 14.0)
    
    func drawInContext(_ context: CGContext) {
        
        UIGraphicsPushContext(context)
        context.setAlpha(1.0)
        
        let nsText = self.text as NSString
        let paragraphStyle:NSMutableParagraphStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = NSTextAlignment.left
        
        let attributes:[String:AnyObject] = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: UIColor.black(),
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        let size:CGSize = nsText.size(attributes: attributes)
        let textRect = CGRect(x: self.rect.origin.x, y: self.rect.origin.y, width: size.width, height: size.height)
        
        nsText.draw(in: textRect, withAttributes: attributes)
        
        UIGraphicsPopContext()
    }
}

struct PDFPathAnnotation:PDFAnnotation {
    
    var path:CGPath
    var color:CGColor
    var alpha:CGFloat
    var fill:Bool
    var lineWidth: CGFloat
    
    func drawInContext(_ context: CGContext) {
        
        context.addPath(self.path)
        context.setLineWidth(self.lineWidth)
        context.setAlpha(self.alpha)
        
        if self.fill {
            context.setFillColor(self.color)
            context.fillPath();
        }
        else {
            context.setStrokeColor(self.color)
            context.strokePath()
        }
    }
}
