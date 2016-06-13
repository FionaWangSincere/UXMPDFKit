//
//  PDFDocument.swift
//  Pods
//
//  Created by Chris Anderson on 3/5/16.
//
//

import UIKit

public class PDFDocument: NSObject, NSCoding {
    
    lazy public var documentRef:CGPDFDocument? = {
        do {
            return try CGPDFDocument.create(self.fileUrl, password: self.password)
        }
        catch {
            return nil
        }
    }()
    
    /// Document Properties
    public var password: String?
    public var lastOpen: Date?
    public var pageCount: Int = 0
    public var currentPage: Int = 1
    public var bookmarks: NSMutableIndexSet = NSMutableIndexSet()
    public var fileUrl: URL
    public var fileSize: Int = 0
    public var guid: String
    
    /// File Properties
    public var title: String?
    public var author: String?
    public var subject: String?
    public var keywords: String?
    public var creator: String?
    public var producer: String?
    public var modificationDate: Date?
    public var creationDate: Date?
    public var version:Float = 0.0
    
    static func documentFromFile(_ filePath: String, password: String?) -> PDFDocument? {
        
        var document:PDFDocument? = PDFDocument.unarchiveDocumentForFile(filePath, password: password)
        
        if document == nil {
            
            document = PDFDocument(filePath: filePath, password: password)
        }
        
        return document
    }
    
    static func unarchiveDocumentForFile(_ filePath: String, password: String?) -> PDFDocument? {
        
        return nil
    }
    
    public required init?(coder aDecoder: NSCoder) {
        
        self.guid = aDecoder.decodeObject(forKey: "fileGUID") as! String
        self.currentPage = aDecoder.decodeObject(forKey: "currentPage") as! Int
        self.bookmarks = aDecoder.decodeObject(forKey: "bookmarks") as! NSMutableIndexSet
        self.lastOpen = aDecoder.decodeObject(forKey: "lastOpen") as? Date
        self.fileUrl = URL(fileURLWithPath: aDecoder.decodeObject(forKey: "fileURL") as! String)
        
        super.init()
        
        self.loadDocumentInformation()
    }
    
    public convenience init(filePath: String) {
        self.init(filePath: filePath, password: nil)
    }
    
    public init(filePath: String, password: String?) {
        
        self.guid = PDFDocument.GUID()
        self.password = password
        self.fileUrl = URL(fileURLWithPath: filePath, isDirectory: false)
        self.lastOpen = Date()
        
        super.init()
        
        self.loadDocumentInformation()
        
        self.save()
    }
    
    func loadDocumentInformation() {
        
        do {
            
            let pdfDocRef:CGPDFDocument = try CGPDFDocument.create(self.fileUrl, password: self.password)
            
            let infoDic:CGPDFDictionaryRef = pdfDocRef.info!
            var string:CGPDFStringRef? = nil
            
            if CGPDFDictionaryGetString(infoDic, "Title", &string) {
                
                if let ref:CFString = CGPDFStringCopyTextString(string!) {
                    self.title = ref as String
                }
            }
            
            if CGPDFDictionaryGetString(infoDic, "Author", &string) {
                
                if let ref:CFString = CGPDFStringCopyTextString(string!) {
                    self.author = ref as String
                }
            }
            
            if CGPDFDictionaryGetString(infoDic, "Subject", &string) {
                
                if let ref:CFString = CGPDFStringCopyTextString(string!) {
                    self.subject = ref as String
                }
            }
            
            if CGPDFDictionaryGetString(infoDic, "Keywords", &string) {
                
                if let ref:CFString = CGPDFStringCopyTextString(string!) {
                    self.keywords = ref as String
                }
            }
            
            if CGPDFDictionaryGetString(infoDic, "Creator", &string) {
                
                if let ref:CFString = CGPDFStringCopyTextString(string!) {
                    self.creator = ref as String
                }
            }
            
            if CGPDFDictionaryGetString(infoDic, "Producer", &string) {
                
                if let ref:CFString = CGPDFStringCopyTextString(string!) {
                    self.producer = ref as String
                }
            }
            
            if CGPDFDictionaryGetString(infoDic, "CreationDate", &string) {
                
                if let ref:CFDate = CGPDFStringCopyDate(string!) {
                    self.creationDate = ref as Date
                }
            }
            
            if CGPDFDictionaryGetString(infoDic, "ModDate", &string) {
                
                if let ref:CFDate = CGPDFStringCopyDate(string!) {
                    self.modificationDate = ref as Date
                }
            }
            
            //            let majorVersion = UnsafeMutablePointer<Int32>()
            //            let minorVersion = UnsafeMutablePointer<Int32>()
            //            CGPDFDocumentGetVersion(pdfDocRef, majorVersion, minorVersion)
            //            self.version = Float("\(majorVersion).\(minorVersion)")!
            
            self.pageCount = pdfDocRef.numberOfPages
            
        } catch let err {
            
            print (err)
        }
    }
    
    
    /////
    /// Helper methods
    /////
    
    static func GUID() -> String {
        
        return ProcessInfo.processInfo().globallyUniqueString
    }
    
    public static func documentsPath() -> String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    public static func applicationPath() -> String {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return (paths.first! as NSString).deletingLastPathComponent
    }
    
    public static func applicationSupportPath() -> String {
        
        let fileManager = FileManager()
        let pathURL = try! fileManager.urlForDirectory(.applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return pathURL.path!
    }
    
    static func archiveFilePathForFileAtPath(_ path: String) -> String {
        
        let archivePath = PDFDocument.applicationSupportPath()
        let archiveName = "random-name-fix-later.plist"
        return (archivePath as NSString).appendingPathComponent(archiveName)
    }
    
    static func isPDF(_ filePath: String) -> Bool {
        
        let state = false
        //        let path = (filePath as NSString).fileSystemRepresentation
        //        var fd = open(path, O_RDONLY)
        //        if fd > 0 {
        //            let sig = UnsafeMutablePointer<Character>.alloc(1024)
        //
        //            var len = read(fd, sig, sizeOfValue(sig))
        //
        //                state = (strnstr(sig, "%PDF", len) != NULL);
        //
        //                close(fd); // Close the file
        //            }
        
        return state;
    }
    
    func archiveWithFileAtPath(_ filePath: String) -> Bool {
        
        let archiveFilePath = PDFDocument.archiveFilePathForFileAtPath(filePath)
        return NSKeyedArchiver.archiveRootObject(self, toFile: archiveFilePath)
    }
    
    public func save() {
        
        self.archiveWithFileAtPath(self.fileUrl.path!)
    }
    
    public func reloadProperties() {
        self.loadDocumentInformation()
    }
    
    public func boundsForPDFPage(_ page:Int) -> CGRect {
        let pageRef = documentRef?.page(at: page)
        
        let cropBoxRect:CGRect = pageRef!.getBoxRect(.cropBox)
        let mediaBoxRect:CGRect = pageRef!.getBoxRect(.mediaBox)
        let effectiveRect:CGRect = cropBoxRect.intersection(mediaBoxRect)
        
        let pageAngle = pageRef?.rotationAngle ?? 0
        
        switch (pageAngle) {
        case 0, 180: // 0 and 180 degrees
            
            return CGRect(
                x: effectiveRect.origin.x,
                y: effectiveRect.origin.y,
                width: effectiveRect.size.width,
                height: effectiveRect.size.height
            )
        case 90, 270: // 90 and 270 degrees
            return CGRect(
                x: effectiveRect.origin.y,
                y: effectiveRect.origin.x,
                width: effectiveRect.size.height,
                height: effectiveRect.size.width
            )
        default:
            return CGRect(
                x: effectiveRect.origin.x,
                y: effectiveRect.origin.y,
                width: effectiveRect.size.width,
                height: effectiveRect.size.height
            )
        }
    }
    
    //    func setCurrentPage(currentPage: Int) {
    //
    //        if currentPage < 1 {
    //            self.currentPage = 1
    //        }
    //        else if currentPage > self.pageCount {
    //            self.currentPage = self.pageCount
    //        }
    //    }
    
    
    /////
    /// Helper methods
    /////
    
    public func encode(with aCoder: NSCoder) {
        
        aCoder.encode(self.guid, forKey: "fileGUID")
        aCoder.encode(self.currentPage, forKey: "currentPage")
        aCoder.encode(self.bookmarks, forKey: "bookmarks")
        aCoder.encode(self.lastOpen, forKey: "lastOpen")
        aCoder.encode(self.fileUrl.path!, forKey: "fileURL")
    }
}
