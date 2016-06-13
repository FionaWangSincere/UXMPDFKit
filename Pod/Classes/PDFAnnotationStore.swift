//
//  PDFAnnotationStore.swift
//  Pods
//
//  Created by Chris Anderson on 5/8/16.
//
//

import UIKit

public class PDFAnnotationStore {
    
    var pages:[Int:PDFAnnotationPage] = [:]
    
    func addAnnotation(_ annotation: PDFAnnotation, page: Int) {
        
        if let storePage:PDFAnnotationPage = pages[page] {
            
            storePage.addAnnotation(annotation)
        }
        else {
            
            let storePage = PDFAnnotationPage()
            storePage.addAnnotation(annotation)
            storePage.page = page
            pages[page] = storePage
        }
    }
    
    func drawAnnotations(_ page: Int, context:CGContext) {
        
        if let storePage = pages[page] {
            for annotation in storePage.annotations {
                annotation.drawInContext(context)
            }
        }
    }
}

public class PDFAnnotationPage {
    
    var annotations:[PDFAnnotation] = []
    var page:Int = 0
    
    func addAnnotation(_ annotation: PDFAnnotation) {
        annotations.append(annotation)
    }
}
