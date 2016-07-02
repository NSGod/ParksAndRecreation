import Foundation

let textURL = #fileLiteral(resourceName: "swift.txt") as URL
let textData = try! String(contentsOf: textURL, encoding: .utf8)

textData.paragraphs
Array(textData.paragraphs)
Array(textData.paragraphs.reversed())

textData.lines
Array(textData.lines)
Array(textData.lines.reversed())
