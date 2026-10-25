import AppKit
import PDFKit
import Foundation

struct Question: Codable { let q:String; let options:[String]; let answer:String }
struct Chapter: Codable { let title:String; let questions:[Question] }
let base = URL(fileURLWithPath:CommandLine.arguments[0]).deletingLastPathComponent().path
let chapters = try JSONDecoder().decode([Chapter].self,from:Data(contentsOf:URL(fileURLWithPath:base+"/questions.json")))
let path = base + "/第五期_第一周_选择题完整答案.pdf"
let W:CGFloat=595.28, H:CGFloat=841.89, margin:CGFloat=44
var media=CGRect(x:0,y:0,width:W,height:H)
let ctx=CGContext(URL(fileURLWithPath:path) as CFURL,mediaBox:&media,[kCGPDFContextTitle:"第五期第一周课后作业：40 道选择题完整答案" as CFString,kCGPDFContextAuthor:"课程学习整理" as CFString] as CFDictionary)!
func color(_ hex:String)->NSColor {
    let n=UInt32(hex,radix:16)!
    return NSColor(srgbRed:CGFloat(n>>16&255)/255,green:CGFloat(n>>8&255)/255,blue:CGFloat(n&255)/255,alpha:1)
}
func attrs(_ size:CGFloat,_ bold:Bool=false,_ ink:String="23333D")->[NSAttributedString.Key:Any] {
    let p=NSMutableParagraphStyle(); p.lineSpacing=3; p.lineBreakMode = .byWordWrapping
    return [.font:NSFont(name:bold ? "PingFangSC-Semibold":"PingFangSC-Regular",size:size)!, .foregroundColor:color(ink),.paragraphStyle:p]
}
func height(_ s:String,_ width:CGFloat,_ size:CGFloat,_ bold:Bool=false)->CGFloat {
    ceil((s as NSString).boundingRect(with:NSSize(width:width,height:10000),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:attrs(size,bold)).height)+1
}
@discardableResult func text(_ s:String,_ x:CGFloat,_ y:CGFloat,_ width:CGFloat,_ size:CGFloat,_ bold:Bool=false,_ ink:String="23333D")->CGFloat {
    let h=height(s,width,size,bold)
    (s as NSString).draw(with:NSRect(x:x,y:y,width:width,height:h+1),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:attrs(size,bold,ink))
    return h
}
func rule(_ y:CGFloat) {
    color("DFE6E4").setStroke();let p=NSBezierPath();p.lineWidth=0.7;p.move(to:NSPoint(x:margin,y:y));p.line(to:NSPoint(x:W-margin,y:y));p.stroke()
}
var page=0
var started=false
func endPage() {
    if started {
        rule(792)
        text("第五期 · 第 1～4 讲 | 每题 2.5 分 · 满分 100 分",margin,804,430,8.5,false,"6B7B81")
        text("\(page)",W-65,803,24,9.5,true,"6B7B81")
        NSGraphicsContext.restoreGraphicsState();ctx.restoreGState();ctx.endPDFPage()
    }
}
func newPage(_ chapter:String,_ continuation:Bool=false) {
    endPage();page += 1;started=true
    ctx.beginPDFPage(nil);ctx.saveGState();ctx.translateBy(x:0,y:H);ctx.scaleBy(x:1,y:-1)
    NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:ctx,flipped:true)
    text("强化学习与 MotrixLab 入门 · 第一周",margin,31,W-2*margin,9.5,false,"6B7B81")
    text("课后选择题 · 完整答案版",margin,53,W-2*margin,21,true)
    text(chapter+(continuation ? "（续）":""),margin,96,W-2*margin,13.5,true,"276D5B")
    rule(123)
}
let letters=["A","B","C","D"]
var qcount=0
for chapter in chapters {
    newPage(chapter.title)
    var y:CGFloat=140
    text("单选题 · 共 10 题 · 本讲 25 分；绿色加粗项为所选答案。",margin,y,W-2*margin,9.2,false,"6B7B81")
    y += 30
    for (i,q) in chapter.questions.enumerated() {
        let title="\(i+1). \(q.q)（2.5 分）"
        let titleH=height(title,W-2*margin,12,true)
        let optionHeights=q.options.enumerated().map { j,s in height("\(letters[j]). \(s)",W-2*margin-14,11,q.answer==letters[j]) }
        let needed=titleH+8+optionHeights.reduce(0,+)+CGFloat(optionHeights.count)*4+23+14
        if y+needed>777 { newPage(chapter.title,true);y=142 }
        if y+needed>777 { fatalError("Question too large: \(chapter.title) \(i+1)") }
        text(title,margin,y,W-2*margin,12,true);y += titleH+8
        for (j,s) in q.options.enumerated() {
            let selected=q.answer==letters[j]
            text("\(letters[j]). \(s)",margin+14,y,W-2*margin-14,11,selected,selected ? "216D56":"33444D")
            y += optionHeights[j]+4
        }
        text("参考答案：\(q.answer)",margin+14,y+2,W-2*margin-14,10,true,"216D56")
        y += 23+14;qcount += 1
    }
}
newPage("答案汇总与核对说明")
text("40 道单选题答案已按本机第 1～4 讲课稿核对。",margin,142,W-2*margin,11)
let xs:[CGFloat]=[44,125,235,345,455]
let colW:[CGFloat]=[70,100,100,100,95]
let headers=["题号","第 1 讲","第 2 讲","第 3 讲","第 4 讲"]
color("EAF2EE").setFill();NSBezierPath(rect:NSRect(x:44,y:176,width:W-88,height:30)).fill()
for j in 0..<5 { text(headers[j],xs[j]+8,182,colW[j]-10,11,true) }
for i in 0..<10 {
    let y:CGFloat=211+CGFloat(i)*29
    text("\(i+1)",xs[0]+8,y,colW[0]-10,11,true)
    for j in 0..<4 {text(chapters[j].questions[i].answer,xs[j+1]+8,y,colW[j+1]-10,11,true,"216D56")}
    rule(y+24)
}
var y:CGFloat=526
y += text("核对说明",margin,y,W-2*margin,13,true)+10
let notes=[
    "1. 第 3 讲第 5 题保留原题“环境类”的措辞。课稿中的 @envcfg(\"cartpole\") 实际装饰配置类 CartpoleCfg；本题仍选 A。",
    "2. 第 3 讲第 7 题按该讲课稿的四项返回值选 B。第 4 讲代码示例另行区分 terminated 与 truncated；实际编程应核对所用接口。",
    "3. 第 4 讲第 7 题按课稿“奖励项互相打架”的表述选 A。示例中的两个速度项合并为 -speed，实际会鼓励降低速度。",
    "资料依据：第五期实训营第 1～4 讲本机 PDF 课稿。题目与选项来自用户提供的作业文本；仅规范排版、标点及缺失题号。第 0 讲平台使用手册不在本次作业范围内。"
]
for n in notes { y += text(n,margin,y,W-2*margin,10,false,"52656D")+9 }
if y>780 { fatalError("Summary overflow: \(y)") }
endPage();ctx.closePDF()
guard let pdf=PDFDocument(url:URL(fileURLWithPath:path)) else { fatalError("PDF not readable") }
let all=pdf.string ?? ""
let answers=all.components(separatedBy:"参考答案：").count-1
guard qcount==40 && answers==40 else {fatalError("Question count mismatch")}
// PDFKit may return CJK radical variants and reorder underscore glyphs.
func normalize(_ s:String)->String {
    var result=s.precomposedStringWithCompatibilityMapping
    for (radical,character) in [("⻔","门"),("⻓","长"),("⻬","齐"),("⻆","角")] {
        result=result.replacingOccurrences(of:radical,with:character)
    }
    return result.filter { !$0.isWhitespace && $0 != "_" }
}
let normalized = normalize(all)
var missing:[String]=[]
for chapter in chapters {
    for q in chapter.questions {
        for s in [q.q]+q.options {
            if !normalized.contains(normalize(s)) { missing.append(s) }
        }
    }
}
if !missing.isEmpty { print("PDF extraction mismatches: \(missing)");exit(1) }
print("PDF: \(path)")
print("Pages: \(pdf.pageCount); questions: \(qcount); answer labels: \(answers)")
for (i,chapter) in chapters.enumerated() {
    print("Lecture \(i+1): \(chapter.questions.map{$0.answer}.joined(separator:" "))")
}
for index in [0,pdf.pageCount-1] {
    let thumb=pdf.page(at:index)!.thumbnail(of:NSSize(width:1190,height:1684),for:.mediaBox)
    let rep=NSBitmapImageRep(data:thumb.tiffRepresentation!)!
    try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"/private/tmp/motrix_quiz_page_\(index+1).png"))
}
