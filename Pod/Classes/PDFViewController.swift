//
//  PDFViewController.swift
//  Pods
//
//  Created by Chris Anderson on 5/7/16.
//
//

import UIKit

public class PDFViewController: UIViewController {
    
    public var hidesBarsOnTap:Bool = false
    
    var document:PDFDocument!
    
    lazy var collectionView:PDFSinglePageViewer = {
        var collectionView = PDFSinglePageViewer(frame: self.view.bounds, document: self.document)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.singlePageDelegate = self
        return collectionView
    }()
    
    lazy var pageScrubber:PDFPageScrubber = {
        
        var pageScrubber = PDFPageScrubber(frame: CGRect(x: 0, y: self.view.frame.size.height - self.bottomLayoutGuide.length, width: self.view.frame.size.width, height: 44.0), document: self.document)
        pageScrubber.scrubberDelegate = self
        pageScrubber.translatesAutoresizingMaskIntoConstraints = false
        return pageScrubber
    }()
    
    lazy var formController:PDFFormViewController = {
        return PDFFormViewController(document: self.document)
    }()
    
    public init(document: PDFDocument) {
        super.init(nibName: nil, bundle: nil)
        self.document = document
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    func setupUI() {
        
        self.view.addSubview(collectionView)
        self.view.addSubview(pageScrubber)
        
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[collectionView]|", options: .alignAllLastBaseline, metrics: nil, views: [ "superview": self.view, "collectionView": self.collectionView])
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[collectionView]|", options: .alignAllLeft, metrics: nil, views: [ "superview": self.view, "collectionView": self.collectionView]))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrubber]|", options: .alignAllLastBaseline, metrics: nil, views: [ "superview": self.view, "scrubber": self.pageScrubber]))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[scrubber(44)]-0-[bottomLayout]", options: .alignAllLeft, metrics: nil, views: [ "scrubber": self.pageScrubber, "bottomLayout": self.bottomLayoutGuide ]))
        
        self.view.addConstraints(constraints)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(PDFViewController.saveForm))
        
        self.pageScrubber.sizeToFit()
        
        if self.hidesBarsOnTap {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PDFViewController.handleTap(_:)))
            gestureRecognizer.cancelsTouchesInView = false
            self.view.addGestureRecognizer(gestureRecognizer)
        }
    }
    
    func loadDocument(_ document: PDFDocument) {
        self.collectionView = PDFSinglePageViewer(frame: self.view.bounds, document: self.document)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.collectionView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)
        self.collectionView.collectionViewLayout.invalidateLayout()
        
        self.view.layoutSubviews()
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            
            self.collectionView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.pageScrubber.sizeToFit()
            
            }, completion: { (context) in
                self.collectionView.displayPage(self.document.currentPage, animated: false)
        })
    }
    
    func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        
        if let nvc = self.navigationController where nvc.isNavigationBarHidden {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.pageScrubber.isHidden = false
        }
        else {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            self.pageScrubber.isHidden = true
        }
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func saveForm() {
        
        DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosDefault).async {
            
            let pdf = self.formController.renderFormOntoPDF()
            DispatchQueue.main.async {
                
                let items = [pdf]
                let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                
                if UIDevice.current().userInterfaceIdiom == .pad {
                    activityVC.modalPresentationStyle = .popover
                    let popController = activityVC.popoverPresentationController
                    popController?.sourceView = self.view
                    popController?.sourceRect = CGRect(x: self.view.frame.width - 34, y: 64, width: 0, height: 0)
                    popController?.permittedArrowDirections = .up
                }
                self.present(activityVC, animated: true, completion: nil)
            }
        }
    }
}


extension PDFViewController: PDFPageScrubberDelegate {
    
    public func scrubber(_ scrubber: PDFPageScrubber, selectedPage: Int) {
        
        self.document.currentPage = selectedPage
        self.collectionView.displayPage(selectedPage, animated: false)
    }
}

extension PDFViewController: PDFSinglePageViewerDelegate {
    
    public func singlePageViewer(_ collectionView: PDFSinglePageViewer, didDisplayPage page: Int) {
        
        self.document.currentPage = page
        self.pageScrubber.updateScrubber()
    }
    
    public func singlePageViewer(_ collectionView: PDFSinglePageViewer, loadedContent content: PDFPageContentView) {
        
        self.formController.showForm(content)
    }
}
