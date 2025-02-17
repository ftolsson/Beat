//
//  DocumentBrowserViewController.swift
//  Beat iOS
//
//  Created by Lauri-Matti Parppei on 14.5.2022.
//  Copyright © 2022 Lauri-Matti Parppei. All rights reserved.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        		
        delegate = self
        
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
        
		overrideUserInterfaceStyle = .dark
		
        // Update the style of the UIDocumentBrowserViewController
        browserUserInterfaceStyle = .dark
        view.tintColor = .white
    }
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        let newDocumentURL: URL? = nil
        
        // Set the URL for the new document here. Optionally, you can present a template chooser before calling the importHandler.
        // Make sure the importHandler is always called, even if the user cancels the creation request.

		if newDocumentURL != nil {
            importHandler(newDocumentURL, .move)
        } else {
			let url = Bundle.main.url(forResource: "Tutorial", withExtension: "fountain")
			importHandler(url, .copy)
        }
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
		print("OK?")
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
		print("PRESENT")
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
		print("FAIL?")
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
        /*
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let documentViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentViewController") as! DocumentViewController
        documentViewController.document = iOSDocument(fileURL: documentURL)
        documentViewController.modalPresentationStyle = .fullScreen
        
        present(documentViewController, animated: true, completion: nil)
		 */
		
		let storyBoard = UIStoryboard(name: "Main", bundle: nil)
		let documentViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentViewController") as! DocumentViewController
		documentViewController.document = iOSDocument(fileURL: documentURL)
		
		let navigationController = UINavigationController(rootViewController: documentViewController)
		navigationController.modalPresentationStyle = .fullScreen
		present(navigationController, animated: true, completion: nil)
    }
}

