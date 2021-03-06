//
//  main.swift
//  CreateNewBlogPost
//
//  Created by Rick Mann on 2021-05-06.
//

import ArgumentParser
import Foundation
import Path
import SystemPackage

struct
CreateNewBlogPost : ParsableCommand
{
	@Option(name: .shortAndLong)
	var				title				:	String
	
	@Option(name: .shortAndLong)
	var				imageURL			:	String?
	
	@Argument(help: "Path to location for new file. If the path specifies a directory, the filename will be automatically generated")
	var				location			:	Path			=	Path(Path.cwd)
	
	
	mutating
	func
	validate()
		throws
	{
		guard
			self.location.isDirectory
				||	!self.location.exists	//	TODO: redundant, as we check again later.
		else
		{
			throw ValidationError("File exists")
		}
	}
	
	mutating
	func
	run()
		throws
	{
		let date = Date()					//	TODO: let user specify.
		
		if self.location.isDirectory
		{
			//	Generate a filename from the date and specified title…
			
			let fileDateFormatter = DateFormatter()
			fileDateFormatter.dateFormat = "yyyy-MM-dd"
			
			let urlTitle = sanitize(title: self.title)
			
			let fileName = "\(fileDateFormatter.string(from: date))-\(urlTitle).md"
			self.location = self.location/fileName
			
			if self.location.exists
			{
				throw ValidationError("File exists: \(self.location)")
			}
		}
		
		//	Substitute values in the template…
		//
		//	TODO: Let the user specify a template. Should probably
		//			 live in a .rc directory in the user’s home dir.
		
		let postDateFormatter = DateFormatter()
		postDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
		let d: [String : String?] =
		[
			"title" : self.title.replacingOccurrences(of: "\"", with: "\\\\\""),		//	lol escape much?
			"date" : postDateFormatter.string(from: date),
			"imageURL" : self.imageURL,
		]
		var contents = sTemplate
		for (key, val) in d
		{
			if let v = val
			{
				let keyExpr = "\\{\\s*?\(key)\\s*?\\}"
				let nc = contents.replacingOccurrences(of: keyExpr, with: v, options: [.regularExpression])
				if nc == contents
				{
					print("No ocurrence of \"\(key)\" in template")
				}
				contents = nc
			}
		}
		
		//	Scour template for additional replacements not satisified…
		
		let re = try NSRegularExpression(pattern: "\\{\\s*?(\\w*?)\\s*?\\}", options: [])
		let matches = re.matches(in: contents, options: [], range: NSMakeRange(0, contents.count))
		if matches.count > 0
		{
			let matchedKeys = matches.map { (contents as NSString).substring(with: $0.range(at: 1)) }
			let mks = matchedKeys.joined(separator: ", ")
			
			var fd = FileDescriptor.standardError
			print("Unmatched keys in template: \(mks)", to: &fd)
		}
		
		//	Create the file and write the contents…
		
		try contents.write(to: self.location, atomically: true, encoding: .utf8)
//		print(contents)
	}
	
	/**
		Converts a string like "How To: Command Line Tools in Swift" into
		"how-to-command-line-tools-in-swift".
	*/
	
	func
	sanitize(title inTitle: String)
		-> String
	{
		var cleanTitle = inTitle.replacingOccurrences(of: " ", with: "-")
		cleanTitle = cleanTitle.filter { !$0.unicodeScalars.contains(where: { !CharacterSet.urlUserAllowed.contains($0) }) }
		cleanTitle.removeAll(where: { "':".contains($0) })
		
		cleanTitle = cleanTitle.lowercased()
		return cleanTitle
	}
	
}

let
sTemplate = """
	---
	layout: post
	title: "{ title }"
	date: { date }
	excerpt: ""
	categories:
	  -
	tags: [frontpage]
	image:
	  path: { imageURL }
	  width:
	  height:
	---

	<div style="text-align: left; margin-bottom: 2em;"><img src="{ imageURL }"></div>
	"""

CreateNewBlogPost.main()

/**
	Allows Path to be directly instantiated by ArgumentParser.
*/

extension
Path : ExpressibleByArgument
{
	public
	init?(argument inArg: String)
	{
		self.init(inArg)
	}
}

/**
	This extension allows us to write
	
	```swift
	var fd = FileDescriptor.standardError
	print("Unmatched keys in template: \(mks)", to: &fd)
	```
	
	Maybe someday the Swift team will enhance `print()` and `FileDecriptor`
	to allow
	
	```swift
	pring("Some error", to: .standardError)
	```
*/

extension
FileDescriptor : TextOutputStream
{
    public mutating func write(_ inString: String) {
        _ = try? FileDescriptor.standardError.writeAll(inString.utf8)
    }
}
