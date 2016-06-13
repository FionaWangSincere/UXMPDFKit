//
//  PDFFormViewController.swift
//  Pods
//
//  Created by Chris Anderson on 5/27/16.
//
//

import Foundation

public class PDFFormViewController:NSObject {
    
    var formPages:[Int:PDFFormPage] = [:]
    
    var document:PDFDocument
    var parser:PDFObjectParser
    var lastPage:PDFPageContentView?
    
    public init(document: PDFDocument) {
        
        self.document = document
        
        self.parser = PDFObjectParser(document: document)
        
        super.init()
        
        self.setupUI()
    }
    
    func setupUI() {
        
        DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosDefault).async {
            
            guard let attributes = self.parser.attributes else {
                return
            }
            
            guard let forms = attributes["AcroForm"] as? PDFDictionary else {
                return
            }
            
            guard let fields = forms.arrayForKey("Fields") else {
                return
            }

            for field in fields {
                if let dictField:PDFDictionary = field as? PDFDictionary {
                    self.enumerate(dictField)
                }
            }

            if let lastPage = self.lastPage {
                DispatchQueue.main.async {
                    self.showForm(lastPage)
                }
            }
        }
    }
    
    func enumerate(_ fieldDict:PDFDictionary) {
        
        if fieldDict["Subtype"] != nil {
            self.createFormField(fieldDict)
            return
        }
        
        guard let array = fieldDict.arrayForKey("Kids") else {
            return
        }
        
        for dict in array {
            if let innerFieldDict:PDFDictionary = dict as? PDFDictionary {
                
                if let type = innerFieldDict["Type"] as? String where type == "Annot" {
                    self.createFormField(innerFieldDict)
                }
                else {
                    self.enumerate(innerFieldDict)
                }
            }
        }
    }
    
    func getPageNumber(_ field:PDFDictionary) -> Int? {
        
        guard let attributes = self.parser.attributes else {
            return nil
        }
        guard let pages = attributes["Pages"] as? PDFDictionary else {
            return nil
        }
        guard let kids = pages.arrayForKey("Kids") else {
            return nil
        }
        
        var page = kids.count()
        
        for kid in kids {
            if let dict = kid as? PDFDictionary,
                let annots = dict.arrayForKey("Annots") {
                for subField in annots {
                    if field.isEqual(subField) {
                        return page
                    }
                }
            }
            page -= 1
        }
        
        return page
    }
    
    func createFormField(_ dict: PDFDictionary) {
        
        if let page = self.getPageNumber(dict) {

            DispatchQueue.main.async {

                if let formView = self.formPage(page) {
                    formView.createFormField(dict)
                }
                else {
                    
                    let formView = PDFFormPage(page: page)
                    formView.createFormField(dict)
                    self.formPages[page] = formView
                }
            }
        }
    }
    
    func showForm(_ contentView:PDFPageContentView) {
        
        self.lastPage = contentView
        let page = contentView.page
        if let formPage = self.formPage(page) {
            formPage.showForm(contentView)
        }
    }
    
    func formPage(_ page: Int) -> PDFFormPage? {
        
        if page > self.formPages.count {
            return nil
        }
        return self.formPages[page]
    }
    
    
    public func renderFormOntoPDF() -> URL {
        let documentRef = document.documentRef
        let pages = document.pageCount
        let title = document.fileUrl.lastPathComponent ?? "annotated.pdf"
        let tempPath = NSTemporaryDirectory() + title
        
        UIGraphicsBeginPDFContextToFile(tempPath, CGRect.zero, nil)
        for i in 1...pages {
            let page = documentRef?.page(at: i)
            let bounds = self.document.boundsForPDFPage(i)
            
            if let context = UIGraphicsGetCurrentContext() {
                UIGraphicsBeginPDFPageWithInfo(bounds, nil)
                context.translate(x: 0, y: bounds.size.height)
                context.scale(x: 1.0, y: -1.0)
                context.drawPDFPage (page!)
                
                context.scale(x: 1.0, y: -1.0)
                context.translate(x: 0, y: -bounds.size.height)
                
                if let form = formPage(i) {
                    form.renderInContext(context, size: bounds)
                }
            }
        }
        UIGraphicsEndPDFContext()
        return URL(fileURLWithPath: tempPath)
    }
    
    public func save(_ url: URL) -> Bool {
        
        let tempUrl = renderFormOntoPDF()
        let fileManger = FileManager.default()
        do {
            try fileManger.copyItem(at: tempUrl, to: url)
        }
        catch _ { return false }
        return true
    }
}
