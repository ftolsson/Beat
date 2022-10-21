//
//  BeatSceneHeadingSearch.swift
//  Beat
//
//  Created by Lauri-Matti Parppei on 9.9.2022.
//  Copyright © 2022 Lauri-Matti Parppei. All rights reserved.
//
/*
 
 This class is a mess but it works. It's also very late, so I don't care.
 
 */

import Cocoa

class BeatSceneHeadingSearch:NSWindowController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, NSControlTextEditingDelegate
 {
	@objc var delegate:BeatEditorDelegate?
	@IBOutlet var textField:NSTextField?
	@IBOutlet var tableView:NSTableView?
	
	var results:[OutlineScene] = []
	
	override var windowNibName: String! {
		return "BeatSceneHeadingSearch"
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override init(window: NSWindow?) {
		super.init(window: window)
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		textField?.delegate = self
		delegate?.parser.createOutline()
		results = delegate?.parser.outline as! [OutlineScene]
		addCloseOnOutsideClick()
	}
	deinit {
		removeCloseOnOutsideClick()
	}
	
	
	override func cancelOperation(_ sender: Any?) {
		// Esc pressed
		//self.closeModal()
		self.closeModal()
	}
	
	
	func controlTextDidChange(_ obj: Notification) {
		filter(textField?.stringValue ?? "")
	}

	//var backspaces:Int = 0
	override func keyUp(with event: NSEvent) {
		// Close on esc
		if event.keyCode == 53 {
			self.closeModal()
			return
		}
		// Select on enter
		else if event.keyCode == 36 {
			selectScene()
		}
		
		else if event.keyCode == 126 {
			// up
			if tableView!.numberOfRows > 0 {
				var selected = tableView!.selectedRow - 1;
				if (selected <= 0) { selected = tableView!.numberOfRows - 1; }
				tableView?.selectRowIndexes([selected], byExtendingSelection: false)
				tableView?.scrollRowToVisible(tableView!.selectedRow)
				return
			}
		}
		else if event.keyCode == 125 {
			// down
			if tableView!.numberOfRows > 0 {
				var selected = tableView!.selectedRow + 1;
				if (selected >= tableView!.numberOfRows) { selected = 0; }
				tableView?.selectRowIndexes([selected], byExtendingSelection: false)
				tableView?.scrollRowToVisible(tableView!.selectedRow)
				return
			}
		}
				
		super.keyUp(with: event)
	}
	
	func closeModal() {
		self.delegate?.documentWindow.endSheet(self.window!)
	}
	
	// MARK: - Filtering and jumping to scene
	
	func selectScene() {
		if (self.tableView!.numberOfRows > 0 && self.tableView!.selectedRow != NSNotFound && self.tableView!.selectedRow >= 0 ) {
			// Get selected scene from the table (usually the first one)
			let scene = self.tableView!.dataSource!.tableView!(self.tableView!, objectValueFor: nil, row: tableView!.selectedRow) as? OutlineScene ?? nil
			
			// Scroll to selected scene and close this menu
			if (scene != nil) {
				self.delegate?.scroll(to: scene!.line)
				closeModal()
				return
			}
		}
		
		// Something went wrong or the search was empty, so just close the dialog
		closeModal()
	}
	
	func filter(_ string:String) {
		if (self.delegate == nil) { return }
		
		if (string.count == 0) {
			results = delegate!.parser.outline as! [OutlineScene]
		} else {
			results = []
		}

		let searchString = string.uppercased()
		
		for item in self.delegate!.parser.outline {
			let scene = item as! OutlineScene
			
			let sceneNumber = (scene.sceneNumber ?? "").uppercased()
			let sceneTitle = scene.string.uppercased()
						
			if sceneTitle.contains(searchString) || sceneNumber.contains(searchString) {
				results.append(scene)
			}
		}
		
		tableView?.reloadData()
		if (tableView!.numberOfRows > 0) {
			tableView?.selectRowIndexes([0], byExtendingSelection: false)
		}
	}
	
	// MARK: - Table view data source and delegate
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return results.count
	}
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		if (item != nil) {
			return 0
		} else {
			return results.count
		}
	}
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		return results[row]
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let scene = results[row]
		let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SceneView"), owner: self) as! BeatSceneHeadingView
		view.textField?.stringValue = scene.stringForDisplay()
		view.sceneNumber?.stringValue = scene.sceneNumber ?? ""
		
		return view
	}
	
	func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
		self.tableView?.selectRowIndexes([row], byExtendingSelection: false)
		selectScene()
		return true
	}
	
	// MARK: - Observe clicks outside the modal
	private var monitor: Any?
	func addCloseOnOutsideClick(ignoring ignoringViews: [NSView]? = nil) {
		monitor = NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.leftMouseDown) { (event) -> NSEvent? in
		
		if !self.window!.contentView!.frame.contains(event.locationInWindow) {
				// If the click is in any of the specified views to ignore, don't hide
				for ignoreView in ignoringViews ?? [NSView]() {
					let frameInWindow: NSRect = ignoreView.convert(ignoreView.bounds, to: nil)
					if frameInWindow.contains(event.locationInWindow) {
						// Abort if clicking in an ignored view
						return event
					}
				}
				
				// Getting here means the click should hide the view
				// Perform your hiding code here
				self.closeModal()
			}
			return event
		}
	}
	func removeCloseOnOutsideClick() {
	   if monitor != nil {
		   NSEvent.removeMonitor(monitor!)
		   monitor = nil
	   }
   }
}

class BeatSceneHeadingView:NSTableCellView {
	@IBOutlet var sceneNumber:NSTextField?
}

class BeatSceneHeadingTextField:NSTextField {
	override func cancelOperation(_ sender: Any?) {
		self.window?.windowController?.cancelOperation(sender)
	}
}
