from copy import deepcopy
from pathlib import Path
from io import BytesIO
from docx import Document
from docx.shared import Inches, Cm, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.style import WD_STYLE_TYPE
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from PIL import Image, ImageDraw, ImageFont

ROOT=Path.cwd()
TEMPLATE=next(Path("E:/.HUIT").glob("Mau bao cao*docx"))
OUT=ROOT/"Bao_cao_do_an_TroPremium.docx"
FONT="Times New Roman"
BLACK=RGBColor(0,0,0)
doc=Document(str(TEMPLATE))
body=doc._element.body
children=list(body)
cover_end=None
middle_break=None
final_sect=body.find(qn("w:sectPr"))
for el in children:
    if el.tag==qn("w:p") and el.xpath(".//w:sectPr"):
        text="".join(el.xpath(".//w:t/text()"))
        if "TP. HỒ CHÍ MINH" in text:
            cover_end=el
        elif cover_end is not None and middle_break is None:
            middle_break=deepcopy(el)
if cover_end is None or middle_break is None or final_sect is None:
    raise RuntimeError("Không xác định được ranh giới hai trang bìa và các section của mẫu.")
cover_index=children.index(cover_end)
for el in list(body)[cover_index+1:]:
    if el is not final_sect:
        body.remove(el)

def set_rfonts(rpr,name=FONT):
    rf=rpr.find(qn("w:rFonts"))
    if rf is None:
        rf=OxmlElement("w:rFonts")
        rpr.insert(0,rf)
    for key in ("ascii","hAnsi","cs","eastAsia"):
        rf.set(qn("w:"+key),name)

def style_font(style,size,bold=False,italic=False):
    style.font.name=FONT
    style.font.size=Pt(size)
    style.font.bold=bold
    style.font.italic=italic
    style.font.color.rgb=BLACK
    set_rfonts(style._element.get_or_add_rPr())

def get_style(name,base="Normal"):
    try:
        return doc.styles[name]
    except KeyError:
        st=doc.styles.add_style(name,WD_STYLE_TYPE.PARAGRAPH)
        st.base_style=doc.styles[base]
        return st

body_style=get_style("BaoCaoNoiDung")
style_font(body_style,13)
body_style.paragraph_format.alignment=WD_ALIGN_PARAGRAPH.JUSTIFY
body_style.paragraph_format.line_spacing=1.3
body_style.paragraph_format.space_before=Pt(6)
body_style.paragraph_format.space_after=Pt(6)
body_style.paragraph_format.first_line_indent=Cm(1)
bullet_style=get_style("BaoCaoBullet")
style_font(bullet_style,13)
bullet_style.paragraph_format.alignment=WD_ALIGN_PARAGRAPH.JUSTIFY
bullet_style.paragraph_format.line_spacing=1.3
bullet_style.paragraph_format.space_before=Pt(6)
bullet_style.paragraph_format.space_after=Pt(6)
bullet_style.paragraph_format.left_indent=Cm(.8)
bullet_style.paragraph_format.first_line_indent=Cm(-.5)
note_style=get_style("BaoCaoGhiChu")
style_font(note_style,11.5,italic=True)
note_style.paragraph_format.alignment=WD_ALIGN_PARAGRAPH.JUSTIFY
note_style.paragraph_format.line_spacing=1.15
note_style.paragraph_format.space_before=Pt(3)
note_style.paragraph_format.space_after=Pt(6)
note_style.paragraph_format.first_line_indent=Cm(.8)
caption_style=get_style("Caption")
style_font(caption_style,12,bold=True)
caption_style.paragraph_format.alignment=WD_ALIGN_PARAGRAPH.CENTER
caption_style.paragraph_format.line_spacing=1.15
caption_style.paragraph_format.space_before=Pt(4)
caption_style.paragraph_format.space_after=Pt(5)
caption_style.paragraph_format.first_line_indent=Cm(0)
caption_style.paragraph_format.keep_with_next=True
for name,size,align in [
    ("Heading 1",18,WD_ALIGN_PARAGRAPH.CENTER),
    ("Heading 2",14,WD_ALIGN_PARAGRAPH.LEFT),
    ("Heading 3",13,WD_ALIGN_PARAGRAPH.LEFT),
]:
    st=get_style(name)
    style_font(st,size,bold=True)
    st.paragraph_format.alignment=align
    st.paragraph_format.first_line_indent=Cm(0)
    st.paragraph_format.line_spacing=1.15
    st.paragraph_format.keep_with_next=True
    st.paragraph_format.keep_together=True
    st.paragraph_format.space_before=Pt(0 if name=="Heading 1" else 8)
    st.paragraph_format.space_after=Pt(14 if name=="Heading 1" else 6)
    ppr=st._element.get_or_add_pPr()
    outline=ppr.find(qn("w:outlineLvl"))
    if outline is None:
        outline=OxmlElement("w:outlineLvl")
        ppr.append(outline)
    outline.set(qn("w:val"),str({"Heading 1":0,"Heading 2":1,"Heading 3":2}[name]))
front_style=get_style("BaoCaoTieuDePhu")
style_font(front_style,18,bold=True)
front_style.paragraph_format.alignment=WD_ALIGN_PARAGRAPH.CENTER
front_style.paragraph_format.first_line_indent=Cm(0)
front_style.paragraph_format.space_before=Pt(0)
front_style.paragraph_format.space_after=Pt(14)
front_style.paragraph_format.line_spacing=1.15
front_style.paragraph_format.keep_with_next=True
ref_style=get_style("BaoCaoTaiLieu")
style_font(ref_style,12)
ref_style.paragraph_format.alignment=WD_ALIGN_PARAGRAPH.JUSTIFY
ref_style.paragraph_format.line_spacing=1.15
ref_style.paragraph_format.space_before=Pt(0)
ref_style.paragraph_format.space_after=Pt(6)
ref_style.paragraph_format.left_indent=Cm(.8)
ref_style.paragraph_format.first_line_indent=Cm(-.8)
for name,size,indent in [("TOC 1",12,0),("TOC 2",11.5,.45),("TOC 3",11,.9),("Table of Figures",12,0)]:
    try:
        st=doc.styles[name]
    except KeyError:
        st=doc.styles.add_style(name,WD_STYLE_TYPE.PARAGRAPH)
    style_font(st,size)
    st.paragraph_format.left_indent=Cm(indent)
    st.paragraph_format.first_line_indent=Cm(0)
    st.paragraph_format.space_before=Pt(0)
    st.paragraph_format.space_after=Pt(4)
    st.paragraph_format.line_spacing=1.15

def set_run(run,size=None,bold=None,italic=None):
    run.font.name=FONT
    run.font.color.rgb=BLACK
    if size is not None: run.font.size=Pt(size)
    if bold is not None: run.bold=bold
    if italic is not None: run.italic=italic
    set_rfonts(run._element.get_or_add_rPr())

def para(text="",style="BaoCaoNoiDung",first_line=True):
    p=doc.add_paragraph(style=style)
    if text: set_run(p.add_run(text))
    if style=="BaoCaoNoiDung" and not first_line:
        p.paragraph_format.first_line_indent=Cm(0)
    return p

def bullet(text,level=1):
    p=doc.add_paragraph(style="BaoCaoBullet")
    if level==1:
        p.paragraph_format.left_indent=Cm(.8)
        p.paragraph_format.first_line_indent=Cm(-.5)
        mark="– "
    else:
        p.paragraph_format.left_indent=Cm(1.3)
        p.paragraph_format.first_line_indent=Cm(-.5)
        mark="+ "
    set_run(p.add_run(mark+text))
    return p

def heading(text,level=1,page_break=False):
    p=doc.add_paragraph(style=f"Heading {level}")
    p.paragraph_format.page_break_before=page_break
    set_run(p.add_run(text),{1:18,2:14,3:13}[level],bold=True)
    return p

def front_heading(text,page_break=True,include_in_toc=False):
    if include_in_toc:
        return heading(text,1,page_break)
    p=doc.add_paragraph(style="BaoCaoTieuDePhu")
    p.paragraph_format.page_break_before=page_break
    set_run(p.add_run(text),18,bold=True)
    return p

def field(p,code,result=""):
    def add_fc(kind):
        r=OxmlElement("w:r")
        f=OxmlElement("w:fldChar")
        f.set(qn("w:fldCharType"),kind)
        r.append(f); p._p.append(r)
    add_fc("begin")
    r=OxmlElement("w:r")
    ins=OxmlElement("w:instrText")
    ins.set("{http://www.w3.org/XML/1998/namespace}space","preserve")
    ins.text=" "+code+" "
    r.append(ins); p._p.append(r)
    add_fc("separate")
    if result: set_run(p.add_run(result),12)
    add_fc("end")

def caption(kind,chapter,number,title,restart=False):
    p=doc.add_paragraph(style="Caption")
    set_run(p.add_run(f"{kind} {chapter}."),12,bold=True)
    field(p,f"SEQ {kind} "+("\\r 1" if restart else "\\* ARABIC"),str(number))
    set_run(p.add_run(": "+title),12,bold=True)
    return p

def source(text):
    p=doc.add_paragraph(style="BaoCaoGhiChu")
    p.paragraph_format.alignment=WD_ALIGN_PARAGRAPH.CENTER
    set_run(p.add_run(text),11.5,italic=True)
    return p

def set_cell(cell,text,bold=False,align=WD_ALIGN_PARAGRAPH.LEFT):
    cell.text=""
    p=cell.paragraphs[0]
    p.alignment=align
    p.paragraph_format.line_spacing=1.3
    p.paragraph_format.space_before=Pt(0)
    p.paragraph_format.space_after=Pt(0)
    p.paragraph_format.first_line_indent=Cm(0)
    set_run(p.add_run(str(text)),12,bold=bold)
    cell.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
    tcpr=cell._tc.get_or_add_tcPr()
    mar=tcpr.find(qn("w:tcMar"))
    if mar is None:
        mar=OxmlElement("w:tcMar"); tcpr.append(mar)
    for side,val in (("top","90"),("start","95"),("bottom","90"),("end","95")):
        el=mar.find(qn("w:"+side))
        if el is None:
            el=OxmlElement("w:"+side); mar.append(el)
        el.set(qn("w:w"),val); el.set(qn("w:type"),"dxa")

def table(chapter,number,title,headers,rows,widths=None,note=None):
    if chapter is not None:
        caption("Bảng",chapter,number,title,restart=(number==1))
    t=doc.add_table(rows=1,cols=len(headers))
    t.style="Table Grid"; t.alignment=WD_TABLE_ALIGNMENT.CENTER; t.autofit=False
    for i,h in enumerate(headers):
        set_cell(t.rows[0].cells[i],h,True,WD_ALIGN_PARAGRAPH.CENTER)
        if widths: t.columns[i].width=Inches(widths[i])
    trpr=t.rows[0]._tr.get_or_add_trPr()
    th=OxmlElement("w:tblHeader"); th.set(qn("w:val"),"true"); trpr.append(th)
    for row in rows:
        cells=t.add_row().cells
        for i,val in enumerate(row):
            set_cell(cells[i],val)
            if widths: cells[i].width=Inches(widths[i])
        t.rows[-1]._tr.get_or_add_trPr().append(OxmlElement("w:cantSplit"))
    if widths:
        for i,w in enumerate(widths): t.columns[i].width=Inches(w)
    if note: source(note)
    return t

def figure(chapter,number,title,data,note):
    p=doc.add_paragraph()
    p.alignment=WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before=Pt(3); p.paragraph_format.space_after=Pt(1)
    p.paragraph_format.keep_together=True
    p.add_run().add_picture(BytesIO(data),width=Inches(5.82))
    caption("Hình",chapter,number,title,restart=(number==1))
    source(note)

FONT_REG=r"C:\Windows\Fonts\times.ttf"
FONT_BOLD=r"C:\Windows\Fonts\timesbd.ttf"
def fnt(size,bold=False):
    try: return ImageFont.truetype(FONT_BOLD if bold else FONT_REG,size)
    except OSError: return ImageFont.load_default()

def wrap_px(draw,text,ft,maxw):
    words=text.split(); lines=[]; line=""
    for word in words:
        test=word if not line else line+" "+word
        if draw.textbbox((0,0),test,font=ft)[2]<=maxw or not line: line=test
        else: lines.append(line); line=word
    if line: lines.append(line)
    return lines

def centered(draw,box,text,ft,spacing=6):
    x1,y1,x2,y2=box; lines=[]
    for part in text.split("\n"): lines+=wrap_px(draw,part,ft,x2-x1-36)
    boxes=[draw.textbbox((0,0),s,font=ft) for s in lines]
    heights=[b[3]-b[1] for b in boxes]
    y=y1+((y2-y1)-(sum(heights)+spacing*(len(lines)-1)))/2
    for s,h,b in zip(lines,heights,boxes):
        draw.text((x1+(x2-x1-(b[2]-b[0]))/2,y),s,font=ft,fill="black")
        y+=h+spacing

def arrow(draw,a,b,width=4,head=16):
    import math
    draw.line([a,b],fill="black",width=width)
    ang=math.atan2(b[1]-a[1],b[0]-a[0])
    p1=(b[0]-head*math.cos(ang-math.pi/6),b[1]-head*math.sin(ang-math.pi/6))
    p2=(b[0]-head*math.cos(ang+math.pi/6),b[1]-head*math.sin(ang+math.pi/6))
    draw.polygon([b,p1,p2],fill="black")

def actor(draw,cx,cy,label):
    ft=fnt(40,True)
    draw.ellipse((cx-32,cy-100,cx+32,cy-36),outline="black",width=5)
    draw.line((cx,cy-36,cx,cy+70),fill="black",width=5)
    draw.line((cx-55,cy,cx+55,cy),fill="black",width=5)
    draw.line((cx,cy+70,cx-50,cy+135),fill="black",width=5)
    draw.line((cx,cy+70,cx+50,cy+135),fill="black",width=5)
    b=draw.textbbox((0,0),label,font=ft)
    draw.text((cx-(b[2]-b[0])/2,cy+145),label,font=ft,fill="black")

def usecase_png():
    im=Image.new("RGB",(2300,1620),"white"); d=ImageDraw.Draw(im)
    d.text((1150,30),"PHẠM VI NGHIỆP VỤ CỦA TROP PREMIUM",font=fnt(55,True),fill="black",anchor="ma")
    d.rounded_rectangle((370,120,1930,1230),radius=20,outline="black",width=5)
    d.text((1150,142),"HỆ THỐNG TROPREMIUM",font=fnt(45,True),fill="black",anchor="ma")
    left=["Tìm kiếm, lọc và xem chi tiết phòng","Gửi yêu cầu xem phòng, theo dõi lịch","Xem hợp đồng và thành viên được duyệt","Xem hóa đơn, gửi minh chứng thanh toán","Báo sự cố, nhắn tin, nhận thông báo"]
    right=["Đăng tin, quản lý nhà và phòng","Xác nhận hoặc đề xuất lịch xem","Lập hợp đồng, quản lý người thuê","Chốt điện nước, lập hóa đơn, đối chiếu","Xử lý sự cố, thông báo, quản lý nhân viên"]
    ys=[285,455,625,795,965]
    for y in ys:
        d.line((250,650,440,y),fill="black",width=3)
        d.line((2050,650,1860,y),fill="black",width=3)
    d.line((1150,1320,1150,1160),fill="black",width=3)
    for y,text in zip(ys,left):
        box=(440,y-57,1110,y+57); d.ellipse(box,outline="black",width=4); centered(d,box,text,fnt(40))
    for y,text in zip(ys,right):
        box=(1190,y-57,1860,y+57); d.ellipse(box,outline="black",width=4); centered(d,box,text,fnt(40))
    box=(640,1080,1660,1185); d.ellipse(box,outline="black",width=4)
    centered(d,box,"Quản trị tài khoản, xác minh / ẩn tin và xử lý hỗ trợ",fnt(40))
    actor(d,190,650,"Người thuê"); actor(d,2110,650,"Chủ trọ"); actor(d,1150,1340,"Quản trị viên")
    d.text((1150,1570),"Các liên kết biểu thị quyền khởi tạo hoặc xử lý nghiệp vụ theo vai trò.",font=fnt(30),fill="black",anchor="ma")
    out=BytesIO(); im.save(out,format="PNG",dpi=(300,300)); return out.getvalue()

def activity_png():
    im=Image.new("RGB",(1900,2700),"white"); d=ImageDraw.Draw(im)
    d.text((950,28),"LUỒNG TỪ TÌM PHÒNG ĐẾN THANH TOÁN",font=fnt(52,True),fill="black",anchor="ma")
    x0=40; lane=606; top=130; bottom=2550
    for i,label in enumerate(["NGƯỜI THUÊ","ỨNG DỤNG","CHỦ TRỌ"]):
        x=x0+i*lane
        d.rectangle((x,top,x+lane,bottom),outline="black",width=3)
        d.rectangle((x,top,x+lane,top+90),outline="black",width=3)
        d.text((x+lane/2,top+44),label,font=fnt(40,True),fill="black",anchor="mm")
    def box(lane_id,y,text,h=118):
        x1=x0+lane_id*lane+58; x2=x0+(lane_id+1)*lane-58
        rect=(x1,y-h/2,x2,y+h/2)
        d.rounded_rectangle(rect,radius=24,outline="black",width=4)
        centered(d,rect,text,fnt(36))
        return (x0+lane_id*lane+lane/2,y)
    cx=x0+lane/2
    d.ellipse((cx-22,238,cx+22,282),fill="black")
    points=[
      (0,350,"Tìm phòng theo khu vực, giá và nhu cầu"),
      (1,500,"Ứng dụng lọc dữ liệu, hiển thị phòng còn đăng"),
      (0,650,"Chọn phòng và gửi thời gian muốn xem"),
      (1,800,"Lưu yêu cầu, gắn người thuê và báo chủ trọ"),
      (2,950,"Chấp nhận, đề xuất giờ khác hoặc từ chối"),
      (0,1100,"Người thuê nhận kết quả và đi xem phòng"),
      (2,1250,"Hai bên thống nhất; chủ trọ lập hồ sơ thuê"),
      (2,1400,"Hai bên ký bản giấy; chủ trọ nhập thông tin"),
      (1,1550,"Lưu hợp đồng, thành viên và phạm vi dữ liệu"),
      (2,1700,"Đến kỳ, chủ trọ nhập chỉ số điện nước"),
      (1,1850,"Kiểm tra chỉ số, tạo hóa đơn theo đơn giá"),
      (0,2000,"Người thuê xem chi tiết và gửi minh chứng"),
      (2,2150,"Chủ trọ đối chiếu rồi duyệt hoặc từ chối"),
    ]
    coords=[box(*item) for item in points]
    arrow(d,(cx,282),(coords[0][0],points[0][1]-60))
    for i in range(len(coords)-1):
        arrow(d,(coords[i][0],points[i][1]+60),(coords[i+1][0],points[i+1][1]-60),width=4,head=14)
    dy=2290; dcx=x0+2*lane+lane/2
    diamond=[(dcx,dy-55),(dcx+80,dy),(dcx,dy+55),(dcx-80,dy)]
    d.polygon(diamond,outline="black",fill="white"); d.line(diamond+[diamond[0]],fill="black",width=4)
    centered(d,(dcx-70,dy-35,dcx+70,dy+35),"Đã khớp?",fnt(30,True))
    arrow(d,(coords[-1][0],points[-1][1]+60),(dcx,dy-55),width=4,head=14)
    centered(d,(1270,2350,1855,2475),"Đạt: cập nhật số đã thu\nChưa đạt: yêu cầu bổ sung",fnt(30))
    d.text((950,2635),"Trong thời gian thuê, người thuê có thể báo sự cố; chủ trọ cập nhật xử lý và người thuê xác nhận hoặc mở lại yêu cầu.",font=fnt(28),fill="black",anchor="ms")
    out=BytesIO(); im.save(out,format="PNG",dpi=(300,300)); return out.getvalue()

def architecture_png():
    im=Image.new("RGB",(2100,1200),"white"); d=ImageDraw.Draw(im)
    d.text((1050,30),"KIẾN TRÚC TRIỂN KHAI VÀ CÁC KÊNH TÍCH HỢP",font=fnt(50,True),fill="black",anchor="ma")
    boxes={
      "ui":(65,190,560,500,"GIAO DIỆN FLUTTER\nNgười thuê • Chủ trọ\nQuản trị viên"),
      "app":(700,190,1260,500,"LỚP ỨNG DỤNG\nĐiều hướng theo vai trò\nStore • kiểm tra dữ liệu\nRepository"),
      "auth":(1450,150,2025,320,"FIREBASE AUTH\nPhiên đăng nhập\nHồ sơ vai trò users/{uid}"),
      "cloud":(1450,390,2025,650,"CLOUD FIRESTORE\nNhà • phòng • hợp đồng\nHóa đơn • thanh toán\nSự cố • lịch xem • tin nhắn"),
      "local":(700,700,1260,980,"SQLITE CỤC BỘ\nCache / dữ liệu theo UID\nAndroid • desktop"),
      "media":(65,700,560,980,"ẢNH VÀ TÀI LIỆU\nCloudinary\nKý upload và URL riêng\nqua Edge Function"),
      "subs":(1450,760,2025,990,"SUPABASE EDGE\nGói thuê bao chủ trọ\nWebhook SePay cho gói"),
      "external":(700,1010,1260,1090,"VietQR • Bản đồ • FCM"),
    }
    arrow(d,(560,345),(700,345)); arrow(d,(1260,260),(1450,235)); arrow(d,(1260,410),(1450,500))
    arrow(d,(980,500),(980,700)); arrow(d,(700,455),(560,735)); arrow(d,(1260,455),(1450,800)); arrow(d,(980,980),(980,1010),head=13)
    for key,(x1,y1,x2,y2,text) in boxes.items():
        d.rounded_rectangle((x1,y1,x2,y2),radius=22,outline="black",width=4,fill="white")
        centered(d,(x1+8,y1+8,x2-8,y2-8),text,fnt(34 if key!="external" else 31,key in ("ui","app","auth","cloud","subs")))
    d.text((1050,1150),"Firestore là nguồn dữ liệu dùng chung; SQLite không thay thế quyền kiểm tra trên máy chủ.",font=fnt(29),fill="black",anchor="ms")
    out=BytesIO(); im.save(out,format="PNG",dpi=(300,300)); return out.getvalue()

def model_png():
    im=Image.new("RGB",(2150,1450),"white"); d=ImageDraw.Draw(im)
    d.text((1075,28),"MÔ HÌNH KHÁI NIỆM DỮ LIỆU NGHIỆP VỤ",font=fnt(50,True),fill="black",anchor="ma")
    nodes={
      "Nhà trọ":(60,150,470,390,["propertyId","ownerUid","published"]),
      "Phòng":(580,150,990,390,["roomId • propertyId","availability • price"]),
      "Hợp đồng":(1100,150,1510,390,["leaseId • roomId","tenantIds • term"]),
      "Thành viên":(1620,150,2030,390,["memberId • leaseId","tenantId • status"]),
      "Chỉ số":(580,520,990,760,["readingId • roomId","period • readings"]),
      "Hóa đơn":(1100,520,1510,760,["invoiceId • leaseId","lines • total • remaining"]),
      "Thanh toán":(1620,520,2030,760,["paymentId • invoiceId","status • proof reference"]),
      "Sự cố":(60,930,470,1170,["incidentId • roomId","reporterId • status"]),
      "Lịch xem":(580,930,990,1170,["viewingId • roomId","tenantId • startsAt"]),
      "Hội thoại":(1100,930,1510,1170,["conversationId","participants • messages"]),
    }
    arrow(d,(470,270),(580,270)); d.text((520,230),"1:N",font=fnt(27,True),fill="black",anchor="mm")
    arrow(d,(990,270),(1100,270)); d.text((1045,230),"1:N",font=fnt(27,True),fill="black",anchor="mm")
    arrow(d,(1510,270),(1620,270)); d.text((1565,230),"1:N",font=fnt(27,True),fill="black",anchor="mm")
    arrow(d,(990,640),(1100,640)); d.text((1045,600),"1:N",font=fnt(27,True),fill="black",anchor="mm")
    arrow(d,(1510,640),(1620,640)); d.text((1565,600),"1:N",font=fnt(27,True),fill="black",anchor="mm")
    arrow(d,(780,390),(780,520)); d.text((830,455),"ghi theo kỳ",font=fnt(26,True),fill="black")
    arrow(d,(1305,390),(1305,520)); d.text((1360,455),"phát sinh",font=fnt(26,True),fill="black")
    arrow(d,(265,390),(265,930)); d.text((310,670),"có sự cố",font=fnt(26,True),fill="black")
    arrow(d,(785,390),(785,930)); d.text((830,830),"đặt lịch",font=fnt(26,True),fill="black")
    arrow(d,(1305,390),(1305,930)); d.text((1355,835),"trao đổi",font=fnt(26,True),fill="black")
    for name,(x1,y1,x2,y2,attrs) in nodes.items():
        d.rectangle((x1,y1,x2,y2),outline="black",width=4,fill="white")
        d.rectangle((x1,y1,x2,y1+58),outline="black",width=3,fill=(235,235,235))
        d.text(((x1+x2)/2,y1+28),name,font=fnt(34,True),fill="black",anchor="mm")
        y=y1+84
        for item in attrs:
            d.text((x1+18,y),item,font=fnt(27),fill="black"); y+=42
    d.text((1075,1290),"Quan hệ nghiệp vụ ở mức khái niệm; Firestore lưu document, không triển khai thành các bảng SQL.",font=fnt(29),fill="black",anchor="ms")
    out=BytesIO(); im.save(out,format="PNG",dpi=(300,300)); return out.getvalue()

# Front matter. The original page-numbered section remains Roman for these pages.
heading("LỜI CẢM ƠN",1,True)
para("Nhóm thực hiện xin chân thành cảm ơn quý thầy cô Khoa Công nghệ Thông tin, Trường Đại học Công Thương Thành phố Hồ Chí Minh đã trang bị nền tảng kiến thức để nhóm có thể tiếp cận bài toán phân tích và xây dựng phần mềm. Nhóm cũng xin cảm ơn giảng viên hướng dẫn đã dành thời gian góp ý về cách xác định phạm vi, trình bày nghiệp vụ và hoàn thiện sản phẩm trong quá trình thực hiện đồ án.")
para("Việc xây dựng một ứng dụng có nhiều vai trò giúp nhóm nhìn rõ hơn mối liên hệ giữa giao diện, dữ liệu và quy tắc phân quyền. Báo cáo được hoàn thiện từ mã nguồn và tài liệu dự án tại thời điểm lập báo cáo; những thiếu sót về khảo sát thực tế hoặc kiểm thử trên thiết bị thật được nêu rõ để tránh nhầm lẫn giữa kết quả đã có và đề xuất tiếp theo.")
para("Nhóm mong nhận được góp ý của quý thầy cô để tiếp tục hoàn thiện ứng dụng và cách trình bày báo cáo.")

front_heading("MỤC LỤC")
p=doc.add_paragraph(); p.paragraph_format.first_line_indent=Cm(0); p.paragraph_format.line_spacing=1.15
field(p,'TOC \\o "1-3" \\h \\z \\u',"Đang cập nhật mục lục")

front_heading("DANH MỤC CÁC KÝ HIỆU VÀ CHỮ VIẾT TẮT",include_in_toc=True)
table(None,None,"Các ký hiệu và chữ viết tắt sử dụng trong báo cáo",
 ["Viết tắt","Tiếng Anh","Diễn giải tiếng Việt"],[
  ("API","Application Programming Interface","Giao diện lập trình ứng dụng"),
  ("CRUD","Create, Read, Update, Delete","Thêm, đọc, cập nhật và xóa dữ liệu"),
  ("DB","Database","Cơ sở dữ liệu"),
  ("FCM","Firebase Cloud Messaging","Dịch vụ gửi thông báo của Firebase"),
  ("NoSQL","Not Only SQL","Nhóm cơ sở dữ liệu phi quan hệ"),
  ("QR","Quick Response","Mã phản hồi nhanh"),
  ("RBAC","Role-Based Access Control","Kiểm soát truy cập theo vai trò"),
  ("SQL","Structured Query Language","Ngôn ngữ truy vấn có cấu trúc"),
  ("UI","User Interface","Giao diện người dùng"),
  ("UID","User Identifier","Mã định danh tài khoản"),
  ("UML","Unified Modeling Language","Ngôn ngữ mô hình hóa thống nhất"),
  ("VND","Vietnamese đồng","Đồng Việt Nam"),
 ],[.75,2.05,3.02],"Nguồn: Nhóm tác giả tổng hợp từ mã nguồn và tài liệu dự án [1].")

front_heading("DANH MỤC HÌNH",include_in_toc=True)
p=doc.add_paragraph(); p.paragraph_format.first_line_indent=Cm(0)
field(p,'TOC \\h \\z \\c "Hình"',"Đang cập nhật danh mục hình")
front_heading("DANH MỤC BẢNG",include_in_toc=True)
p=doc.add_paragraph(); p.paragraph_format.first_line_indent=Cm(0)
field(p,'TOC \\h \\z \\c "Bảng"',"Đang cập nhật danh mục bảng")

# Start the original Arabic-numbered section before the introduction.
body.insert(body.index(final_sect),middle_break)
heading("MỞ ĐẦU",1,True)
para("Thị trường thuê trọ tạo ra nhiều giao dịch lặp lại giữa người tìm phòng, chủ trọ và người đang thuê. Một phòng có thể được đăng tin, hẹn xem, chuyển trạng thái, lập hợp đồng, ghi chỉ số dịch vụ và thanh toán qua nhiều kênh khác nhau. Khi thông tin nằm rải rác trong sổ, bảng tính và tin nhắn, hai bên khó kiểm tra lại một quyết định đã thống nhất hoặc biết dữ liệu nào đang là bản mới nhất.")
para("Đồ án xây dựng TroPremium như một ứng dụng Flutter hỗ trợ ba vai trò Người thuê, Chủ trọ và Quản trị viên. Trọng tâm của sản phẩm là nối các thao tác thường gặp thành một luồng có trạng thái: tìm phòng và gửi lịch xem; ghi nhận hợp đồng; chốt chỉ số, phát hành hóa đơn và đối chiếu khoản thanh toán; tiếp nhận sự cố và xác nhận xử lý. Dữ liệu dùng chung được tổ chức trên Firebase, còn ứng dụng giữ kho cục bộ theo tài khoản cho các nền tảng phù hợp [1].")
para("Phương pháp thực hiện gồm đọc mã nguồn và tài liệu kỹ thuật trong dự án, lập danh sách tác nhân và quyền, mô hình hóa luồng nghiệp vụ bằng Use Case và sơ đồ hoạt động, sau đó đối chiếu các màn hình, repository, quy tắc Firestore và tài liệu kiểm thử. Báo cáo không ghi nhận phỏng vấn hay đo đạc tại một nhà trọ cụ thể. Vì vậy, phần khảo sát hiện trạng trình bày một quy trình tham chiếu phổ biến, còn kết quả phần mềm được mô tả theo những gì có thể xác nhận từ dự án.")
para("Phạm vi tập trung vào quản lý cho thuê phòng và các tương tác thiết yếu quanh hợp đồng. Ứng dụng chưa thay thế chữ ký hợp đồng ngoài đời, chưa tự xác nhận tiền thuê chỉ từ ảnh chuyển khoản và chưa chứng minh khả năng vận hành thương mại qua thử nghiệm thực địa. Các giới hạn này được phân biệt với phần đã cài đặt ở Chương 4 và dùng làm căn cứ cho hướng phát triển ở Chương 5.")
para("Báo cáo gồm năm chương: Chương 1 giới thiệu đề tài; Chương 2 khảo sát theo kịch bản và phân tích nghiệp vụ; Chương 3 trình bày tích hợp, lưu trữ, giao diện và bảo vệ dữ liệu; Chương 4 mô tả công nghệ, kết quả theo vai trò và bằng chứng kiểm thử hiện có; Chương 5 tổng kết, nêu hạn chế và đề xuất các bước tiếp theo.")

# CHƯƠNG 1
heading("CHƯƠNG 1: GIỚI THIỆU ĐỀ TÀI",1,True)
heading("1.1. TỔNG QUAN VỀ HỆ THỐNG QUẢN LÝ NHÀ TRỌ",2)
para("Quản lý nhà trọ là chuỗi công việc bắt đầu từ việc giới thiệu chỗ ở và kết thúc khi hợp đồng được thanh lý. Ở giữa hai mốc đó, chủ trọ phải theo dõi phòng nào còn trống, ai đang thuê, điều khoản nào đang có hiệu lực, các khoản dịch vụ được tính ra sao và yêu cầu sửa chữa đã được giải quyết đến đâu. Người thuê lại cần nhìn thấy thông tin phù hợp với hợp đồng của mình, biết khoản nào đến hạn và có nơi gửi phản ánh.")
para("Một hệ thống thông tin cho bài toán này cần nối dữ liệu nhà trọ với từng phòng, hợp đồng và người thuê. Trạng thái phòng không nên chỉ là một nhãn được chỉnh độc lập: khi hợp đồng có hiệu lực, phòng được xem là đang thuê; khi hợp đồng kết thúc, phòng có thể được mở lại để đăng. Việc lưu lịch sử hợp đồng và hóa đơn cũng quan trọng, vì thay đổi giá mới không được làm mất căn cứ tính của kỳ đã phát hành.")
para("TroPremium tổ chức trải nghiệm theo ba vai trò. Người thuê dùng các chức năng khám phá tin đăng, gửi lịch xem, theo dõi chỗ ở, hóa đơn, thành viên và sự cố. Chủ trọ quản lý nhà, phòng và quy trình vận hành. Quản trị viên theo dõi nền tảng, xử lý hỗ trợ và kiểm duyệt thông tin công khai. Mỗi vai trò dùng chung một bộ dữ liệu nhưng chỉ nhìn thấy phần được cấp quyền.")
para("Ứng dụng sử dụng Flutter cho giao diện, Firebase Authentication để xác thực tài khoản và Cloud Firestore làm nguồn dữ liệu dùng chung. Kho SQLite trên thiết bị được tách theo UID để hỗ trợ lưu trữ cục bộ; bản web truy cập Firestore trực tiếp. Mô hình này cho phép dùng lại phần lớn giao diện và nghiệp vụ trên nhiều nền tảng, nhưng bản thân việc dùng chung mã nguồn không loại bỏ khác biệt về cấu hình, quyền truy cập hay kiểm thử theo thiết bị [1], [2], [3].")
heading("1.2. LÝ DO CHỌN ĐỀ TÀI",2)
para("Nghiệp vụ cho thuê có nhiều bước nhỏ nhưng liên quan chặt chẽ. Chỉ cần một phòng đã có người đặt nhưng tin đăng vẫn hiển thị còn trống, người thuê có thể mất thời gian liên hệ vô ích. Nếu chỉ số điện nước và đơn giá được lưu ở hai nơi, hóa đơn cuối kỳ khó giải thích. Khi phản ánh hư hỏng nằm trong cuộc trò chuyện cá nhân, chủ trọ có thể không tìm lại được ngày nhận yêu cầu hoặc lần sửa trước.")
para("Bài toán cũng phù hợp để vận dụng kiến thức phát triển ứng dụng đa nền tảng và thiết kế dữ liệu theo vai trò. Một màn hình đẹp chưa đủ để giải quyết nhu cầu; ứng dụng cần giữ ranh giới giữa dữ liệu công khai của tin đăng và hồ sơ riêng của người thuê. Các thao tác như duyệt thanh toán hoặc kết thúc sự cố phải phản ánh được trạng thái cho cả hai bên, thay vì chỉ đổi màu một nút trên thiết bị.")
para("Nhóm chọn đề tài để xây dựng một sản phẩm có thể trình bày bằng luồng nghiệp vụ cụ thể, từ lúc tìm phòng đến khi quản lý một kỳ thuê. Việc này giúp đánh giá được cả giao diện lẫn các quyết định kỹ thuật: định danh người thuê, phân quyền truy vấn, lưu lịch sử và xử lý khi hai thiết bị thay đổi dữ liệu gần nhau. Mục tiêu của đồ án là tạo nền tảng có thể tiếp tục thử nghiệm, không tuyên bố thay thế quy trình pháp lý hoặc hệ thống kế toán chuyên dụng.")
heading("1.3. MỤC TIÊU CỦA ỨNG DỤNG",2)
para("Mục tiêu tổng quát là phân tích, thiết kế và triển khai TroPremium nhằm hỗ trợ tìm kiếm phòng và quản lý những nghiệp vụ thường gặp của một kỳ thuê. Các mục tiêu thành phần gồm:")
bullet("Xây dựng giao diện theo ba vai trò, giúp người dùng đi đến chức năng đúng với nhiệm vụ của mình.")
bullet("Hỗ trợ chủ trọ quản lý nhà, phòng, lịch xem, hợp đồng, thành viên, chỉ số điện nước, hóa đơn, xác nhận thanh toán và sự cố.")
bullet("Cho phép người thuê tìm phòng, gửi yêu cầu xem, xem hồ sơ thuê được liên kết với tài khoản, nhận hóa đơn, gửi minh chứng thanh toán và theo dõi yêu cầu sửa chữa.")
bullet("Tổ chức dữ liệu theo UID, chủ sở hữu và người thuê; áp dụng kiểm tra truy cập tại Firestore Rules để giới hạn hồ sơ riêng.")
bullet("Kết nối các dịch vụ phục vụ xác thực, dữ liệu, hình ảnh, QR chuyển khoản và một số tiện ích vận hành; giữ thông tin bí mật phía máy chủ.")
bullet("Mô tả và đối chiếu một tập kịch bản nghiệp vụ, đồng thời chỉ ra phần nào đã có bằng chứng kiểm thử và phần nào cần thử nghiệm trực tiếp.")
heading("1.4. PHẠM VI ĐỀ TÀI",2)
para("Đề tài tập trung vào quản lý nhà trọ theo đơn vị nhà và phòng, với một hợp đồng gắn với một phòng và người thuê đại diện cùng các thành viên đã được duyệt. Người thuê có thể xem danh sách tin công khai, yêu thích phòng, yêu cầu lịch xem, trao đổi, xem hợp đồng và thực hiện các tương tác trong thời gian thuê. Chủ trọ thiết lập thông tin nhà/phòng và xử lý các bản ghi nghiệp vụ liên quan.")
para("Phần tài chính trong ứng dụng gồm cấu hình dịch vụ, nhập chỉ số, tạo hóa đơn, hiển thị các dòng tính và nhận yêu cầu thanh toán kèm minh chứng. QR VietQR được dùng để hướng dẫn chuyển tiền; trạng thái khoản thu vẫn cần chủ trọ kiểm tra và xác nhận. Mã nguồn còn có luồng thuê bao dành cho chủ trọ, nơi webhook SePay liên kết với đơn thuê bao; luồng này khác với việc tự động đối soát tiền thuê của người thuê [1], [11].")
para("Ứng dụng có mã nguồn cho Android, web và Windows; dữ liệu dùng chung dựa trên Firebase, trong khi SQLite được sử dụng ở các nền tảng có cấu hình tương ứng. Báo cáo không đánh giá hiệu năng trên quy mô thương mại, không xác minh pháp lý nhà trọ, không triển khai chữ ký điện tử có giá trị pháp lý, không tự động đối soát mọi giao dịch ngân hàng và không đưa ra kết luận dựa trên khảo sát thực địa.")

# CHƯƠNG 2
heading("CHƯƠNG 2: KHẢO SÁT VÀ PHÂN TÍCH HỆ THỐNG",1,True)
heading("2.1. KHẢO SÁT HIỆN TRẠNG",2)
heading("2.1.1. Đối tượng và phạm vi khảo sát",3)
para("Phạm vi khảo sát của đồ án được xác định từ ba nhóm có tương tác trực tiếp với quy trình thuê: người đang tìm hoặc thuê phòng, chủ trọ/người quản lý và quản trị viên nền tảng. Các nghiệp vụ được xem xét gồm công bố phòng, hẹn xem, lập hồ sơ thuê, tính tiền theo kỳ, tiếp nhận thanh toán và xử lý yêu cầu sửa chữa.")
para("Trong dữ liệu dự án không có biên bản phỏng vấn, phiếu khảo sát hoặc tên cơ sở lưu trú cụ thể. Vì vậy, nội dung dưới đây là phân tích nghiệp vụ tham chiếu được xây dựng từ các chức năng và mô hình dữ liệu của TroPremium, không đại diện cho kết quả điều tra xã hội học. Khi triển khai đồ án tại một nhà trọ cụ thể, cần xác nhận lại cách chốt điện nước, ngày thu tiền, phí dịch vụ và cách lưu chứng từ với người quản lý.")
para("Đối tượng chính của phần mềm là nhà trọ quy mô nhỏ và vừa cần một nơi quản lý danh mục phòng cùng các giao dịch lặp lại. Phạm vi không đi sâu vào quản lý tòa nhà thương mại, đặt cọc trực tuyến, tính thuế, xuất hóa đơn điện tử theo chuẩn cơ quan thuế hoặc nghiệp vụ môi giới chuyên nghiệp.")
heading("2.1.2. Cách quản lý nhà trọ hiện tại",3)
para("Trong quy trình tham chiếu, chủ trọ đăng thông tin phòng qua biển báo, mạng xã hội hoặc trang rao vặt. Người tìm phòng gọi điện hoặc nhắn tin để hỏi tình trạng, giá, tiền cọc và thời gian có thể đến xem. Hai bên tự thống nhất lịch; chủ trọ có thể ghi lịch trong sổ hoặc lịch cá nhân. Tin đăng thường được sửa sau khi chủ trọ nhớ cập nhật, nên thông tin trên kênh công khai có thể chậm hơn tình trạng thực.")
para("Khi đồng ý cho thuê, chủ trọ thu thập thông tin người thuê và lập hợp đồng giấy. Bản hợp đồng, ảnh giấy tờ và thông tin người ở có thể được lưu ở nhiều vị trí. Nếu người ở ghép thay đổi, chủ trọ cập nhật qua tin nhắn hoặc phụ lục riêng. Việc tìm lại hợp đồng cũ thường phụ thuộc vào cách đặt tên và cất hồ sơ.")
para("Đến kỳ thanh toán, chủ trọ đọc đồng hồ, ghi lại số đầu kỳ và số cuối kỳ, nhân mức tiêu thụ với đơn giá, cộng tiền phòng và dịch vụ. Hóa đơn thường được gửi qua tin nhắn. Người thuê chuyển khoản hoặc trả tiền mặt, sau đó gửi ảnh hoặc báo miệng. Chủ trọ kiểm tra tài khoản ngân hàng rồi đánh dấu đã thu. Sự cố như hỏng khóa, rò nước hay thiết bị điện thường được báo qua điện thoại; lịch sửa và kết quả xử lý có thể không thành một hồ sơ riêng.")
heading("2.1.3. Khó khăn của chủ trọ và người thuê",3)
para("Với chủ trọ, việc ghi cùng một thông tin vào tin đăng, sổ hợp đồng và bảng tính tạo ra nguy cơ sai khác. Khi quản lý nhiều nhà, việc kiểm tra phòng còn trống hoặc khoản thu đến hạn tốn thời gian. Nếu đơn giá thay đổi mà hóa đơn cũ không giữ lại mức giá tại thời điểm phát hành, việc giải thích chênh lệch về sau trở nên khó khăn.")
para("Người thuê thường phải hỏi lại các điều khoản đã trao đổi, không có một nơi thống nhất để xem hóa đơn, số tiền đã trả và số còn thiếu. Một ảnh chuyển khoản chưa được xác nhận có thể bị hiểu nhầm là giao dịch đã hoàn tất. Khi sự cố được báo qua nhiều kênh, người thuê khó biết yêu cầu đã được tiếp nhận, đang chờ thợ hay đã đóng.")
para("Ở cấp nền tảng, danh sách tin, tài khoản và yêu cầu hỗ trợ cần có công cụ kiểm duyệt. Nếu quyền quản trị chỉ nằm ở giao diện mà không được kiểm tra khi truy cập dữ liệu, người dùng có thể thử gọi trực tiếp thao tác ngoài màn hình. Vì vậy, hệ thống cần vừa làm rõ quy trình trên giao diện, vừa kiểm tra quyền ở lớp dữ liệu.")
table(2,1,"Nhóm khó khăn ghi nhận trong quy trình tham chiếu",
 ["Đối tượng","Biểu hiện","Tác động đến nghiệp vụ"],[
  ("Chủ trọ","Tình trạng phòng, hợp đồng và thu tiền nằm ở nhiều sổ/kênh","Mất thời gian đối chiếu; dễ bỏ sót hoặc nhập sai"),
  ("Người thuê","Khó xem lại điều khoản, hóa đơn và trạng thái yêu cầu","Phải liên hệ nhiều lần; thiếu căn cứ khi trao đổi"),
  ("Quản trị viên","Tin đăng và hỗ trợ cần rà soát nhưng thiếu dấu vết tập trung","Khó phản hồi thống nhất và theo dõi quyết định"),
 ],[1.1,2.55,2.17],"Nguồn: Nhóm tác giả tổng hợp theo kịch bản nghiệp vụ; không phải số liệu đo tại một cơ sở cụ thể.")

heading("2.2. XÁC ĐỊNH YÊU CẦU HỆ THỐNG",2)
heading("2.2.1. Đối tượng sử dụng và phạm vi quyền hạn",3)
para("Hệ thống nhận diện người dùng bằng UID của tài khoản đã đăng nhập. Vai trò mô tả nhóm quyền rộng, còn quyền đọc hoặc sửa bản ghi cụ thể còn phụ thuộc vào chủ sở hữu nhà, mã người thuê, thành viên hợp đồng và trạng thái công khai. Cách gắn quyền với tài nguyên này tránh giả định rằng mọi người mang cùng một vai trò đều có thể xem toàn bộ dữ liệu của nhau.")
table(2,2,"Tác nhân và giới hạn quyền trong ứng dụng",
 ["Tác nhân","Quyền nghiệp vụ chính","Giới hạn"],[
  ("Người thuê","Tìm phòng công khai; gửi lịch xem; xem hợp đồng, thành viên được duyệt, hóa đơn; gửi minh chứng; tạo sự cố và trao đổi","Chỉ đọc hồ sơ thuê gắn với tenantId của tài khoản; không sửa giá, hợp đồng hoặc chỉ số đã chốt"),
  ("Chủ trọ","Quản lý nhà/phòng của mình; hợp đồng, người thuê, dịch vụ, chỉ số, hóa đơn, khoản thu, lịch xem và sửa chữa","Không đọc/sửa hồ sơ của nhà khác nếu chưa được cấp quyền quản lý"),
  ("Quản trị viên","Quản trị tài khoản và hỗ trợ; rà soát/xác minh tin; ẩn hoặc hiện nội dung theo chức năng quản trị","Quyền quản trị được cấp qua hồ sơ đáng tin cậy; không cho tài khoản tự đăng ký tự nâng quyền"),
 ],[1.0,2.8,2.02],"Nguồn: Mã nguồn và quy tắc truy cập của dự án [1], [10].")
heading("2.2.2. Chức năng cần hỗ trợ theo vai trò",3)
para("Các yêu cầu được gom theo kết quả người dùng cần đạt thay vì theo tên màn hình. Một luồng chỉ được xem là hoàn tất khi trạng thái mới được lưu và bên còn lại có thể nhìn thấy thông tin phù hợp với quyền của mình.")
table(2,3,"Yêu cầu chức năng cốt lõi theo vai trò",
 ["Mã","Vai trò","Yêu cầu chức năng","Kết quả mong đợi"],[
  ("YC-01","Người thuê","Tìm, lọc, xem chi tiết và lưu phòng yêu thích","Chỉ thấy tin được công khai; bộ lọc phản ánh kết quả đang tải"),
  ("YC-02","Người thuê / Chủ trọ","Tạo, xác nhận, đề xuất lại hoặc hủy lịch xem","Hai bên thấy cùng trạng thái và thời gian đã thống nhất"),
  ("YC-03","Chủ trọ / Người thuê","Lập hồ sơ thuê, liên kết tài khoản và thành viên","Người thuê xem đúng hợp đồng của mình; lịch sử không biến mất"),
  ("YC-04","Chủ trọ","Nhập chỉ số, lập hóa đơn và phát hành theo kỳ","Mỗi dòng hóa đơn thể hiện đơn giá/cách tính dùng tại kỳ đó"),
  ("YC-05","Người thuê / Chủ trọ","Gửi chứng từ và duyệt hoặc từ chối khoản thanh toán","Khoản thu chờ xác nhận không bị coi là đã thanh toán"),
  ("YC-06","Người thuê / Chủ trọ","Báo sự cố, cập nhật xử lý và xác nhận kết quả","Yêu cầu có trạng thái, người xử lý và lịch sử trao đổi"),
  ("YC-07","Quản trị viên","Rà soát tài khoản, tin đăng và yêu cầu hỗ trợ","Thao tác quản trị có phạm vi rõ ràng và phản ánh lên dữ liệu"),
 ],[.55,1.05,2.55,1.67],"Nguồn: Nhóm tác giả phân rã chức năng từ các luồng hiện có trong mã nguồn [1].")
heading("2.2.3. Yêu cầu chung về bảo mật và tính dễ sử dụng",3)
para("Về bảo mật, tài khoản phải được xác thực trước khi truy cập dữ liệu riêng. Vai trò admin không được cấp từ biểu mẫu đăng ký; các truy vấn của chủ trọ cần ràng buộc ownerUid, còn hồ sơ người thuê cần ràng buộc tenantIds hoặc tenantId tương ứng. Quy tắc Firestore cần từ chối đọc và ghi trái phạm vi ngay cả khi người dùng tự tạo yêu cầu ngoài giao diện [5].")
para("Hợp đồng, hóa đơn, bằng chứng thanh toán và giấy tờ xác minh chứa thông tin nhạy cảm. Ứng dụng chỉ nên lưu tham chiếu tệp trong cơ sở dữ liệu, giới hạn quyền tải tệp riêng tư và không đưa khóa bí mật dịch vụ vào ứng dụng di động. Các thao tác phát hành hóa đơn hoặc xác nhận thanh toán cần kiểm tra dữ liệu liên quan trước khi ghi; nếu có thay đổi đồng thời, ứng dụng phải báo xung đột thay vì âm thầm ghi đè.")
para("Về dễ sử dụng, trạng thái cần có cả chữ và màu để người dùng không phải suy đoán ý nghĩa của biểu tượng. Biểu mẫu phải chỉ ra lỗi ngay tại trường nhập, còn trạng thái tải, rỗng và lỗi mạng phải có nội dung rõ. Danh sách dài cần tìm kiếm hoặc phân trang; người dùng quay lại tab nên giữ vị trí và bộ lọc nếu dữ liệu chưa bị thay đổi.")
para("Hệ thống cần hiển thị tiền bằng VND, ngày theo múi giờ phù hợp và đơn vị điện nước nhất quán. Mọi hành động có ảnh hưởng đến quyền lợi như gửi yêu cầu, hủy, duyệt hoặc từ chối cần có phản hồi và trạng thái lưu. QR chuyển khoản là phương tiện hướng dẫn thanh toán; giao dịch chỉ được ghi nhận sau bước xác nhận của người có quyền.")

heading("2.3. PHÂN TÍCH NGHIỆP VỤ QUẢN LÝ NHÀ TRỌ",2)
heading("2.3.1. Tìm phòng, hẹn xem và xác nhận lịch",3)
para("Chủ trọ tạo thông tin nhà và phòng gồm địa chỉ, giá, diện tích, tiện ích, ảnh và tình trạng công khai. Chỉ phòng còn khả dụng thuộc nhà được công bố mới xuất hiện trong kết quả tìm. Người thuê có thể lọc theo khu vực, mức giá, diện tích và một số tiêu chí phòng; ứng dụng sử dụng truy vấn phân trang để không tải toàn bộ danh mục trong một lần [12].")
para("Khi chọn phòng, người thuê mở chi tiết và gửi yêu cầu xem với ngày giờ dự kiến cùng thông tin liên hệ cần thiết. Yêu cầu được gắn với người gửi, phòng và chủ sở hữu nhà. Chủ trọ kiểm tra lịch, sau đó chấp nhận, đề xuất thời gian khác hoặc từ chối. Khi có thay đổi, ứng dụng cập nhật trạng thái và thông báo cho người gửi. Yêu cầu xem không tự động giữ chỗ; việc đặt cọc hoặc chuyển phòng sang trạng thái đã thuê thuộc bước thỏa thuận tiếp theo.")
para("Luồng phải xử lý trường hợp lịch không còn phù hợp, phòng đã có hợp đồng khác hoặc chủ trọ tạm dừng nhận lịch. Người thuê có thể theo dõi danh sách yêu cầu của mình và hủy khi chưa diễn ra. Việc tách yêu cầu xem khỏi hợp đồng giúp hệ thống không khóa phòng chỉ vì một người vừa gửi lịch.")
heading("2.3.2. Bàn giao phòng, ký và quản lý hợp đồng thuê",3)
para("Sau buổi xem, nếu hai bên thống nhất cho thuê, chủ trọ chọn đúng nhà/phòng và tạo hồ sơ hợp đồng. Hồ sơ gồm người thuê đại diện, thời hạn, tiền thuê, tiền cọc, chu kỳ thanh toán, giới hạn người ở và điều khoản liên quan. Mã người thuê được dùng để liên kết tài khoản với hồ sơ; thành viên ở ghép chỉ được xem dữ liệu sau khi yêu cầu tham gia được xử lý theo quy trình.")
para("Hai bên ký hợp đồng giấy hoặc thực hiện hình thức ký riêng ngoài ứng dụng. TroPremium lưu thông tin quản lý và hiển thị nội dung hợp đồng; thao tác trong ứng dụng không được xem là chữ ký điện tử có giá trị pháp lý. Khi hợp đồng có hiệu lực, trạng thái phòng được suy ra từ hồ sơ đang thuê. Khi gia hạn, đổi phòng hoặc kết thúc, cần tạo cập nhật có mốc thời gian và giữ lại lịch sử cũ.")
para("Lúc bàn giao, chủ trọ có thể ghi nhận hiện trạng phòng, chỉ số ban đầu, chìa khóa và tài sản đi kèm trong biên bản riêng. Những hạng mục này là hướng nghiệp vụ nên được chuẩn hóa thêm nếu triển khai tại cơ sở thực tế; báo cáo không khẳng định ứng dụng hiện đã có quy trình ký biên bản bàn giao số hoàn chỉnh.")
heading("2.3.3. Chốt chỉ số điện nước, lập hóa đơn và đối chiếu thanh toán",3)
para("Đầu kỳ hoặc khi nhận phòng, chủ trọ ghi lại chỉ số ban đầu. Đến kỳ tính tiền, chủ trọ nhập chỉ số mới và ngày chốt. Hệ thống kiểm tra chỉ số mới không thấp hơn chỉ số trước trong tình huống đồng hồ không được thay; phần tiêu thụ được tính bằng hiệu hai chỉ số. Nếu đồng hồ được thay hoặc chỉ số có bất thường, người nhập cần có diễn giải và xử lý riêng thay vì để phép tính tạo ra số âm.")
para("Hóa đơn được tạo từ tiền phòng, điện, nước, dịch vụ và các khoản điều chỉnh được cấu hình. Với mỗi dòng, ứng dụng cần giữ đơn vị tính, số lượng, đơn giá và thành tiền. Hóa đơn đã phát hành phải giữ lại bản chụp đơn giá của kỳ đó để việc cập nhật bảng giá mới không làm thay đổi khoản cũ. Chủ trọ rà soát trước khi phát hành; hóa đơn nháp có thể sửa, còn hóa đơn đã phát hành cần luồng hủy hoặc điều chỉnh có dấu vết.")
para("Người thuê xem hạn trả, từng dòng chi phí, số đã thanh toán và số còn lại. QR có thể điền thông tin tài khoản và nội dung chuyển khoản; người thuê gửi mã giao dịch hoặc ảnh minh chứng. Chủ trọ đối chiếu giao dịch thật rồi duyệt hoặc từ chối kèm lý do. Hệ thống chỉ cộng khoản thu được duyệt vào số đã thanh toán. Cách làm này tránh lấy ảnh QR hoặc ảnh chuyển khoản làm bằng chứng tự động rằng tiền đã vào tài khoản.")
para("Nếu người thuê trả một phần, hóa đơn giữ số dư còn lại và cho phép gửi thêm khoản thanh toán sau. Nếu hai bên phát hiện sai chỉ số, cần hủy hoặc tạo hóa đơn điều chỉnh theo quyền hạn; không nên sửa ngược một hóa đơn đã được dùng làm căn cứ thanh toán.")
heading("2.3.4. Báo sự cố, sửa chữa và xác nhận kết quả",3)
para("Người thuê tạo yêu cầu bằng cách chọn phòng/hợp đồng, mô tả hiện tượng, mức độ ưu tiên và đính kèm hình ảnh nếu cần. Yêu cầu cần ghi người gửi và thời điểm tạo; thông tin cho phép vào phòng để sửa chữa chỉ được chia sẻ với người xử lý có liên quan.")
para("Chủ trọ tiếp nhận, trao đổi thêm, phân công người xử lý và cập nhật trạng thái trong quá trình sửa. Khi công việc hoàn tất, người thuê kiểm tra và xác nhận. Nếu tình trạng chưa khắc phục, người thuê có thể mở lại yêu cầu theo chính sách của ứng dụng. Các bước này giữ lịch sử trao đổi gắn với sự cố, giúp hai bên không phải dựa hoàn toàn vào tin nhắn rời.")
para("Trường hợp cần xử lý khẩn cấp như nguy cơ chập điện hoặc rò rỉ nước, ứng dụng không thay thế việc gọi trực tiếp cho người phụ trách. Hệ thống cần hướng dẫn người dùng ưu tiên liên hệ khẩn cấp và không chờ thông báo đẩy.")

heading("2.4. MÔ HÌNH HÓA NGHIỆP VỤ",2)
heading("2.4.1. Sơ đồ Use Case tổng quát",3)
para("Sơ đồ tổng quát thể hiện ba tác nhân chính và nhóm chức năng mỗi vai trò được khởi tạo hoặc xử lý. Người thuê bắt đầu các yêu cầu gắn với nhu cầu cá nhân; chủ trọ xử lý tài nguyên thuộc nhà mình; quản trị viên xử lý tài khoản, tin đăng và hỗ trợ ở cấp nền tảng. Các đường nối biểu thị tương tác, còn việc đọc/ghi cụ thể vẫn được kiểm tra tại Firestore Rules.")
figure(2,1,"Sơ đồ Use Case tổng quát của TroPremium",usecase_png(),"Nguồn: Nhóm tác giả xây dựng từ chức năng trong mã nguồn [1].")
para("Sơ đồ không mô tả mọi trang con hay trường hợp ngoại lệ. Các hành động như xác nhận thanh toán, đổi lịch và đóng sự cố có trạng thái trung gian; phần đó được làm rõ ở các quy trình chi tiết và sơ đồ hoạt động bên dưới.")
heading("2.4.2. Sơ đồ hoạt động",3)
para("Sơ đồ hoạt động mô tả đường đi tiêu biểu từ lúc người thuê tìm phòng đến khi hóa đơn được đối chiếu. Việc tạo hợp đồng chỉ diễn ra sau khi hai bên đã trao đổi và thống nhất trực tiếp; bước ký giấy được thể hiện như hoạt động ngoài ứng dụng. Trong thời gian thuê, luồng báo sự cố là một nghiệp vụ độc lập, có thể phát sinh song song với các kỳ hóa đơn.")
figure(2,2,"Luồng hoạt động tìm phòng, lập hợp đồng và thanh toán",activity_png(),"Nguồn: Nhóm tác giả mô hình hóa dựa trên quy trình nghiệp vụ và trạng thái dữ liệu [1].")
para("Tại bước chốt chỉ số, ứng dụng cần từ chối dữ liệu không hợp lệ hoặc yêu cầu người nhập giải trình. Tại bước đối chiếu tiền, kết quả chờ duyệt chưa làm giảm số dư; chỉ quyết định của chủ trọ mới cập nhật trạng thái khoản thu. Hai điểm kiểm soát này làm rõ trách nhiệm của từng bên và hạn chế việc một thao tác giao diện bị hiểu nhầm thành kết quả cuối cùng.")

# CHƯƠNG 3
heading("CHƯƠNG 3: THIẾT KẾ HỆ THỐNG",1,True)
heading("3.1. CÁC DỊCH VỤ VÀ NỀN TẢNG TÍCH HỢP",2)
para("TroPremium dùng Flutter và Dart để tổ chức giao diện theo các nhóm trang riêng cho chủ trọ, người thuê và quản trị viên. Flutter cung cấp bộ widget và lớp kết xuất dùng chung; các plugin bổ sung khả năng kết nối dịch vụ nền tảng. Trong dự án, Firebase được khởi tạo theo cấu hình nền tảng trong firebase_options.dart [1], [2], [3].")
para("Firebase Authentication giữ phiên đăng nhập. Sau khi xác thực, ứng dụng đọc hồ sơ users/{uid} để xác định vai trò và mã người thuê; thông tin này không được lấy từ một vai trò do người dùng tùy ý chọn trên màn hình. Cloud Firestore lưu danh mục nhà/phòng và các bản ghi nghiệp vụ. Các truy vấn theo vai trò được giới hạn bằng ownerUid, tenantIds và Firestore Rules.")
para("SQLite là kho cục bộ được tách theo UID ở Android/desktop. Nó hỗ trợ khôi phục trạng thái trên thiết bị và lưu dữ liệu trong phạm vi repository; bản web truy cập Firestore trực tiếp. Không nên hiểu kho cục bộ là bản sao thay thế mọi nghiệp vụ cloud hoặc mặc định rằng mọi thao tác đều dùng được khi ngoại tuyến [1], [7].")
para("Ảnh tải mới được chuyển qua Cloudinary. Supabase Edge Functions cấp chữ ký upload hoặc URL tải riêng sau khi kiểm tra token Firebase và quyền truy cập đối tượng. Supabase cũng lưu các dữ liệu phục vụ thuê bao của chủ trọ; webhook SePay xử lý khoản chuyển đến cho đơn thuê bao. Đây là một nhánh dịch vụ riêng, không tự động xác nhận tiền thuê phòng [11].")
para("Với hóa đơn thuê, VietQR cung cấp danh sách ngân hàng và đường dẫn tạo mã QR theo thông tin chủ trọ. Ứng dụng dùng QR như chỉ dẫn để người thuê chuyển khoản, sau đó gửi yêu cầu thanh toán để chủ trọ kiểm tra. Geolocation/geocoding hỗ trợ chọn khu vực hoặc vị trí; Google Maps được mở để xem địa chỉ. Firebase Messaging và thông báo cục bộ được dùng trong phần đăng ký, nhận và hiển thị thông báo khi cấu hình nền tảng cho phép.")
table(3,1,"Nền tảng tích hợp và trách nhiệm trong hệ thống",
 ["Thành phần","Dữ liệu hoặc nhiệm vụ","Ranh giới cần lưu ý"],[
  ("Flutter / Dart","Giao diện đa nền tảng, điều hướng và logic phía ứng dụng","Không dùng giao diện làm nơi duy nhất để kiểm tra quyền"),
  ("Firebase Authentication","Đăng nhập và UID tài khoản","Role và tenantId được đọc từ hồ sơ tin cậy"),
  ("Cloud Firestore","Nhà, phòng, hợp đồng và các bản ghi vận hành","Rules kiểm tra quyền ở cấp dữ liệu; tài liệu có cấu trúc NoSQL"),
  ("SQLite","Kho cục bộ theo tài khoản trên nền tảng có hỗ trợ","Không phải nguồn dữ liệu cloud cho bản web"),
  ("Cloudinary + Supabase Functions","Tải ảnh, tạo URL riêng và kiểm tra quyền tệp","Khóa ký và bí mật dịch vụ chỉ ở phía máy chủ"),
  ("VietQR / SePay","QR hướng dẫn thanh toán tiền thuê; webhook thuê bao chủ trọ","Không đồng nhất hai luồng; QR không tự duyệt hóa đơn"),
  ("Maps / FCM","Mở bản đồ và chuyển thông báo","Cần cấu hình quyền, khóa nền tảng và kiểm thử trên thiết bị"),
 ],[1.35,2.45,1.92],"Nguồn: Mã nguồn, pubspec.yaml và tài liệu tích hợp của dự án [1], [11].")
figure(3,1,"Kiến trúc triển khai và các kênh tích hợp",architecture_png(),"Nguồn: Nhóm tác giả tổng hợp từ cấu trúc lib/data và backend/supabase [1], [11].")
para("Luồng dữ liệu chính đi từ màn hình theo vai trò qua store/repository đến Firestore. Với thao tác có nhiều bản ghi liên quan, repository có thể dùng transaction và so sánh phiên bản để giảm nguy cơ ghi mất cập nhật đồng thời. Firestore hỗ trợ transaction nguyên tử, nhưng transaction phía client cần kết nối mạng và có thể được thực thi lại khi phát hiện xung đột; vì vậy logic bên trong transaction không nên tạo tác dụng phụ ngoài dữ liệu [6].")

heading("3.3. THIẾT KẾ LƯU TRỮ DỮ LIỆU",2)
para("Kho dữ liệu cloud được thiết kế theo document thay vì lược đồ bảng quan hệ. Firestore tổ chức document trong collection; mỗi document có trường khóa-giá trị, có thể chứa map hoặc danh sách. Vì vậy, sơ đồ bên dưới biểu diễn quan hệ nghiệp vụ để người đọc hiểu liên kết, không phải sơ đồ các bảng SQL vật lý [4].")
table(3,2,"Các nhóm document chính trong Firestore",
 ["Collection / nhóm","Nội dung","Khóa liên kết và mục đích"],[
  ("users","Hồ sơ tài khoản, role, tenantId, trạng thái","Document ID là UID; không cho client tự sửa quyền"),
  ("rental_properties","Thông tin nhà trọ, chủ sở hữu, cấu hình và trạng thái công khai","ownerUid xác định chủ trọ; chứa dữ liệu phục vụ quản lý nhà"),
  ("public_rooms","Thông tin phòng được truy vấn cho khám phá","propertyId, trạng thái published/available, giá và đặc điểm"),
  ("rental_records","Hợp đồng, thành viên, chỉ số, hóa đơn, khoản thu, sự cố, lịch xem, hội thoại","Mỗi record có propertyId, ownerUid và tenantIds phù hợp"),
  ("user_state","Thiết lập và trạng thái cá nhân","Tách khỏi hồ sơ hợp đồng và dữ liệu người dùng khác"),
  ("management / support_tickets","Dữ liệu quản trị, thuê bao hoặc hỗ trợ","Quyền đọc ghi giới hạn theo tác vụ quản trị"),
 ],[1.55,2.3,1.87],"Nguồn: Thiết kế và codec dữ liệu trong dự án [1]; mô hình document đối chiếu tài liệu Firestore [4].")
para("Mỗi bản ghi nghiệp vụ có định danh riêng và các trường dùng để truy vấn theo chủ sở hữu hoặc người thuê. Ví dụ, hợp đồng giữ roomId, tenantIds và thời hạn; hóa đơn giữ leaseId, dòng chi tiết, tổng tiền, khoản đã thu và số còn lại; yêu cầu sự cố gắn phòng, người gửi, trạng thái và các cập nhật. Mã người thuê được xác thực qua hồ sơ tài khoản để tránh ghép dữ liệu chỉ dựa trên họ tên hoặc số điện thoại.")
para("Bản cục bộ SQLite hiện dùng bảng app_documents để lưu các snapshot JSON có kiểu, kèm mã tài khoản và thời điểm cập nhật. Đây là lựa chọn thuận tiện cho repository hiện có nhưng chưa tạo một bảng quan hệ cho từng loại nghiệp vụ. Việc tìm kiếm và báo cáo phức tạp vẫn phụ thuộc vào cách chuẩn hóa payload, chỉ mục cloud và giới hạn truy vấn.")
para("Ảnh và giấy tờ được lưu ngoài document; Firestore giữ khóa hoặc tham chiếu. Tệp công khai như ảnh tin có thể phân phối theo chính sách công khai, còn chứng từ thanh toán và hồ sơ xác minh cần URL có thời hạn hoặc luật đọc theo đối tượng. Rules của Cloud Storage cũng cho phép giới hạn quyền theo đường dẫn và kiểm tra metadata tệp [14].")
figure(3,2,"Mô hình khái niệm các thực thể nghiệp vụ",model_png(),"Nguồn: Nhóm tác giả mô hình hóa từ codec và các model trong lib/pages [1].")
para("Một quy tắc quan trọng là không xóa lịch sử tài chính chỉ để ẩn phòng khỏi danh sách. Phòng ngừng cho thuê có thể được lưu trữ hoặc bỏ công khai; hợp đồng, hóa đơn và giao dịch cũ vẫn cần tra cứu trong phạm vi quyền phù hợp. Khi cập nhật đồng thời, ứng dụng cần hợp nhất trường độc lập hoặc báo xung đột ở trường bị sửa từ hai thiết bị.")

heading("3.4. THIẾT KẾ GIAO DIỆN VÀ ĐIỀU HƯỚNG THEO VAI TRÒ",2)
para("Giao diện khởi động tại luồng đăng nhập và đọc lại hồ sơ tài khoản trước khi mở vùng dữ liệu riêng. Sau khi biết role, RoleLayoutShell chọn layout tương ứng; các route con tiếp tục kiểm tra mã người thuê hoặc dữ liệu nhà đang hoạt động. Một tài khoản có thể tham gia nhiều quan hệ, nhưng giao diện vận hành cần chỉ rõ nhà hoặc hợp đồng nào đang được chọn.")
para("Khu vực Người thuê ưu tiên tìm phòng và theo dõi nơi ở. Tab Khám phá hỗ trợ tìm kiếm, lọc, xem chi tiết và giữ trạng thái khi chuyển tab. Các trang Chỗ ở của tôi, Hợp đồng, Thành viên, Hóa đơn, Sự cố, Lịch xem, Tin nhắn, Thông báo và Hỗ trợ được tổ chức theo nhu cầu sử dụng. Hóa đơn hiện số còn phải trả, kỳ, hạn và các giao dịch theo trạng thái; người thuê có thể gửi chứng từ nhưng không tự duyệt khoản thu của mình.")
para("Khu vực Chủ trọ bắt đầu từ tổng quan danh mục. Chủ trọ chuyển giữa các nhà, quản lý tầng/phòng và loại phòng, tiếp nhận lịch xem, lập hợp đồng, quản lý thành viên, bảng giá dịch vụ, chỉ số điện nước, hóa đơn, tài khoản nhận tiền, khoản thu, sự cố, nhân viên và thông báo. Luồng thanh toán đặt trạng thái chờ xác nhận riêng để tránh người thuê gửi lặp khi chưa có quyết định.")
para("Khu vực Quản trị viên cung cấp bảng tổng quan, tài khoản, thống kê, kiểm tra/xác minh tin đăng, ẩn hoặc hiện tin và xử lý hỗ trợ. Các tiện ích thuê bao và đối soát dành cho chủ trọ có phân luồng riêng. Việc xác minh nhà trọ trong ứng dụng chỉ dựa trên thông tin và tài liệu được cung cấp; không thay thế thẩm định quyền sở hữu hay kiểm tra pháp lý.")
para("Các danh sách lớn sử dụng phân trang, lọc và trạng thái tải/rỗng/lỗi. Bộ lọc khám phá được áp dụng vào truy vấn trước khi phân trang ở những điều kiện Firestore hỗ trợ; một số từ khóa vẫn cần lọc theo lô nhỏ vì Firestore không tìm chuỗi con như công cụ toàn văn. Tài liệu dự án ghi nhận cơ chế giữ danh sách cũ khi làm mới lỗi mạng và giới hạn số document đọc cho từng truy vấn [12].")
para("Các màn hình dùng chung nút quay lại, tiêu đề trang con, thẻ trạng thái và biểu mẫu. Trên màn hình hẹp, một số biểu mẫu chuyển bố cục để tránh tràn ngang. Cải tiến tiếp theo nên đưa kiểm tra khả năng tiếp cận vào định nghĩa hoàn thành: nhãn cho trình đọc màn hình, vùng chạm, cỡ chữ lớn, tương phản và hỗ trợ bàn phím.")

heading("3.5. THIẾT KẾ PHÂN QUYỀN VÀ BẢO VỆ DỮ LIỆU",2)
para("Xác thực trả về UID, sau đó ứng dụng đọc hồ sơ users/{uid} từ server để lấy role và tenantId. Người đăng ký có thể khởi tạo tài khoản Chủ trọ hoặc Người thuê theo quy tắc đăng ký; quyền admin không được tạo từ client. Nếu hồ sơ không tồn tại, bị khóa hoặc không đọc được, ứng dụng không nên suy diễn từ cache của tài khoản khác để mở dữ liệu riêng.")
para("Firestore Rules là điểm cưỡng chế quyền đối với các yêu cầu từ client. Chủ trọ được giới hạn theo ownerUid; người thuê được giới hạn theo tenantIds trong hợp đồng hoặc bản ghi liên quan; người chưa đăng nhập chỉ đọc được tập tin công khai đúng điều kiện. Admin được nhận diện từ hồ sơ đã tin cậy. Cách bố trí này dựa trên nguyên tắc tách xác thực danh tính khỏi quyết định cho phép hành động [5].")
para("Các nghiệp vụ như duyệt một khoản thanh toán cần cập nhật khoản thu và số dư hóa đơn trong cùng transaction. Repository kiểm tra phiên bản dữ liệu để tránh quyết định cũ ghi đè thay đổi mới. Transaction Firestore có tính nguyên tử khi thành công; tuy nhiên, thao tác có thể bị chạy lại khi xung đột và không hoạt động khi thiết bị ngoại tuyến. Vì thế, thông báo thành công chỉ nên hiển thị sau khi server xác nhận [6].")
para("Tệp riêng tư được phân loại theo người có liên quan. Ảnh chứng từ chỉ dành cho chủ trọ, người thuê có hóa đơn và admin theo quy tắc; hồ sơ xác minh chỉ dành cho chủ nhà tương ứng và admin. Chữ ký Cloudinary được cấp ở Edge Function sau khi kiểm tra Firebase ID token và quyền Firestore; URL tải riêng có thời hạn. Khóa API hoặc secret webhook không được đặt trong mã Flutter [8], [11].")
para("Một lớp bảo vệ khác là giới hạn dữ liệu cần đọc. Khám phá không tải toàn bộ tài sản riêng của người thuê; danh mục nhà và phòng công khai được phân trang, còn records riêng được truy vấn theo UID, ownerUid hoặc tenantId. Lỗi permission-denied phải dừng luồng dữ liệu liên quan thay vì giữ một trang có thể đang chứa thông tin từ phiên cũ.")
para("Dù đã có quy tắc truy cập, việc bảo vệ dữ liệu vẫn phụ thuộc vào triển khai đúng môi trường và rà soát định kỳ. Trước khi dùng dữ liệu thật cần kiểm tra Rules đang được publish khớp với bản nguồn, cấu hình Storage/Cloudinary đang bật đúng, backup có thể khôi phục và các vai trò được thử bằng tài khoản riêng. Báo cáo kiểm thử nội bộ cũng lưu ý một số bước chưa được thử tay trên thiết bị thật [10].")

# CHƯƠNG 4
heading("CHƯƠNG 4: CÀI ĐẶT KIỂM THỬ VÀ KẾT QUẢ",1,True)
heading("4.1. CÔNG NGHỆ VÀ MÔI TRƯỜNG CHẠY ỨNG DỤNG",2)
para("Ứng dụng được viết bằng Dart trên Flutter. Manifest pubspec.yaml khai báo các gói chính cho Firebase Core, Authentication, Cloud Firestore, Cloud Storage, SQLite, bản đồ, định vị, ảnh, SVG, URL và thông báo. Các phiên bản cụ thể cần lấy từ pubspec.yaml và pubspec.lock đi kèm bản nộp; chúng có thể thay đổi khi dependency được cập nhật.")
table(4,1,"Thành phần công nghệ trong bản đồ án",
 ["Nhóm","Công nghệ trong dự án","Vai trò sử dụng"],[
  ("Giao diện","Flutter, Dart, Material widgets","Dựng layout theo role, biểu mẫu và điều hướng"),
  ("Đăng nhập / cloud","firebase_core, firebase_auth, cloud_firestore","Khởi tạo Firebase, xác thực và đọc ghi document"),
  ("Kho cục bộ","sqflite, sqflite_common_ffi","Lưu snapshot cục bộ trên nền tảng cấu hình tương ứng"),
  ("Tệp / ảnh","image_picker, Cloudinary gateway","Chọn ảnh, tải ảnh có chữ ký và lấy URL theo quyền"),
  ("Bản đồ / mạng","geolocator, geocoding, url_launcher, http","Chọn vị trí, chuyển tới bản đồ và gọi API"),
  ("Thông báo","firebase_messaging, flutter_local_notifications","Đăng ký và hiển thị thông báo theo cấu hình nền tảng"),
  ("Dịch vụ máy chủ","Supabase Edge Functions, Postgres, SePay","Ký tải media và xử lý thuê bao chủ trọ"),
 ],[1.15,2.35,2.2],"Nguồn: pubspec.yaml, mã nguồn và tài liệu tích hợp [1], [11].")
para("Môi trường chạy cần Flutter SDK phù hợp với ràng buộc Dart trong pubspec.yaml, Android SDK/emulator cho bản Android hoặc trình duyệt cho bản web, kết nối Internet và Firebase project đã cấu hình. Cấu hình web đọc Firestore trực tiếp; SQLite cần được khởi tạo theo đúng nền tảng. Gói sqflite mô tả SQLite như cơ sở dữ liệu dạng tệp cho ứng dụng Flutter, còn nền tảng desktop cần factory tương ứng [7].")
para("Quy trình khởi động dành cho môi trường phát triển là cài dependency bằng flutter pub get, kiểm tra cấu hình Firebase trong firebase_options.dart và tệp cấu hình nền tảng, sau đó chạy flutter run. Có thể tạo bản Android bằng flutter build apk --debug. Dự án không nên đưa khóa riêng của Cloudinary, SePay hoặc Supabase server vào tham số build công khai; các bí mật này nằm ở cấu hình máy chủ.")
para("Với máy web, các thao tác chọn tệp, bản đồ và thông báo chịu ràng buộc bởi trình duyệt và quyền người dùng. Trên Android, kết quả còn phụ thuộc quyền vị trí, thông báo, camera/thư viện và cấu hình Google Maps. Do đó, một lần chạy thành công trên Windows hoặc widget test không thay thế việc kiểm tra APK trên thiết bị.")

heading("4.2. KẾT QUẢ TRIỂN KHAI THEO BA VAI TRÒ",2)
para("Mã nguồn hiện tổ chức luồng riêng cho cả ba vai trò, dùng repository và store chung khi cần đồng bộ dữ liệu. Các chức năng dưới đây được đối chiếu theo trang, model và luồng dữ liệu trong dự án; đây là mô tả phạm vi triển khai, không phải kết luận rằng mọi tính năng đã được nghiệm thu trên thiết bị thật.")
table(4,2,"Kết quả chức năng thể hiện theo vai trò",
 ["Vai trò","Nhóm màn hình / nghiệp vụ","Kết quả người dùng nhận được"],[
  ("Người thuê","Khám phá và chi tiết phòng; yêu thích; lịch xem; chỗ ở/hợp đồng; thành viên; hóa đơn và thanh toán; tin nhắn; sự cố; thông báo; hỗ trợ","Tìm và theo dõi phòng; xem hồ sơ gắn với tenantId; gửi yêu cầu, chứng từ và phản ánh; xem trạng thái do chủ trọ cập nhật"),
  ("Chủ trọ","Tổng quan; danh mục nhà/phòng; loại phòng; nhân viên; lịch xem; hợp đồng/thành viên; dịch vụ và chỉ số; hóa đơn; tài khoản nhận tiền; khoản thu; sự cố; thông báo","Quản lý dữ liệu thuộc ownerUid; chốt kỳ và phát hành hóa đơn; duyệt khoản thu; xử lý việc phát sinh"),
  ("Quản trị viên","Tổng quan và thống kê; người dùng/tài khoản; kiểm duyệt/xác minh tin; hỗ trợ; thiết lập quản trị và thuê bao","Theo dõi nền tảng, rà soát nội dung, hỗ trợ người dùng và xử lý các mục quản trị theo quyền"),
 ],[1.0,2.35,2.35],"Nguồn: Cấu trúc trang, router, store và tài liệu dự án [1].")
para("Ở vai trò Người thuê, màn hình hóa đơn dùng số dư thực tế của hóa đơn; QR đi cùng tài khoản nhận tiền của chủ trọ và nội dung chuyển khoản. Nếu chủ trọ chưa duyệt, khoản gửi vẫn ở trạng thái chờ. Ở vai trò Chủ trọ, việc chấp nhận hoặc từ chối thanh toán cập nhật trạng thái và được phản ánh cho người thuê. Trong kiểm duyệt, thông tin thiếu hoặc thay đổi cần được xem xét lại; trạng thái xác minh không phải xác nhận pháp lý.")
para("Bên cạnh các chức năng này, dữ liệu công khai được truy vấn phân trang và kho cục bộ tách theo UID. Các màn hình quản lý dùng biểu mẫu tạo/sửa và trạng thái lưu. Tổ chức theo vai trò giúp người dùng không phải đi qua một bảng điều khiển chung có quá nhiều thao tác không liên quan.")

heading("4.3. KIỂM THỬ NGHIỆP VỤ VÀ PHÂN QUYỀN",2)
para("Bộ kịch bản cần kiểm tra gồm luồng đúng, dữ liệu biên và truy cập sai quyền. Với từng thao tác ghi, cần kiểm tra cả trạng thái trên màn hình lẫn dữ liệu được đọc lại từ repository hoặc emulator. Các kịch bản dưới đây là ma trận nghiệm thu phù hợp với chức năng; trạng thái lịch sử được tổng hợp riêng ở Bảng 4.4.")
table(4,3,"Ma trận kịch bản kiểm thử nghiệp vụ",
 ["Mã","Kịch bản","Điều kiện đạt"],[
  ("TC-01","Đăng nhập và đọc hồ sơ vai trò","Tài khoản chỉ mở đúng layout sau khi hồ sơ server hợp lệ"),
  ("TC-02","Người thuê thử đọc hợp đồng của tenant khác","Firestore từ chối; trang không hiển thị dữ liệu ngoài phạm vi"),
  ("TC-03","Chủ trọ thử sửa nhà có ownerUid khác","Firestore từ chối; dữ liệu cũ không bị thay đổi"),
  ("TC-04","Tìm phòng, đổi bộ lọc và chuyển trang","Không lặp phòng; con trỏ tiếp tục đúng; lỗi mạng giữ kết quả cũ"),
  ("TC-05","Gửi lịch xem và chủ trọ đổi trạng thái","Hai vai trò nhìn cùng trạng thái sau khi đồng bộ"),
  ("TC-06","Nhập chỉ số và phát hành hóa đơn","Chỉ số không hợp lệ bị chặn; dòng tiền giữ đơn giá và phép tính"),
  ("TC-07","Gửi minh chứng, duyệt hoặc từ chối thanh toán","Chưa duyệt không tăng khoản đã thu; quyết định có lý do/trạng thái"),
  ("TC-08","Báo sự cố, hoàn tất rồi mở lại","Lịch sử trạng thái còn; tenant chỉ xác nhận yêu cầu liên quan"),
  ("TC-09","Tải ảnh riêng tư bằng tài khoản không liên quan","Yêu cầu bị từ chối hoặc URL hết hạn không tải được"),
  ("TC-10","Tạo hai cập nhật đồng thời trên cùng hóa đơn","Transaction/xung đột không làm mất khoản thu hoặc ghi trùng"),
 ],[.55,2.45,2.7],"Nguồn: Nhóm tác giả xây dựng theo luồng nghiệp vụ và quy tắc quyền trong mã nguồn [1], [5].")
para("Tài liệu kiểm tra đồng bộ vai trò trong dự án ghi nhận 250 bài kiểm tra Flutter đạt, phân tích tĩnh không phát hiện issue và các kịch bản Firestore Emulator về quyền công khai/riêng, owner/tenant, chống tự nâng role, duyệt thanh toán, tin nhắn và transaction đạt tại thời điểm lập biên bản 04/11/2026 [10]. Tài liệu tối ưu Khám phá ghi nhận 70 bài kiểm tra truy vấn và điều hướng đạt trong phạm vi tính năng đó [12]; nhóm này nằm trong ngữ cảnh kiểm tra tính năng, không được cộng thêm vào con số bộ đầy đủ.")
para("Những kết quả trên là nhật ký có sẵn trong repository, không phải lượt chạy mới cho báo cáo này. Tài liệu cũng nêu chưa đăng nhập ba tài khoản trên thiết bị Android thật để chạy trọn luồng từ người thuê sang chủ trọ rồi quay lại, và kiểm thử Emulator không chứng minh trạng thái production. Vì vậy, báo cáo không tuyên bố đã nghiệm thu giao dịch thật, chất lượng SMS, thông báo trên mọi thiết bị hoặc hiệu năng ngoài thực tế [10].")
table(4,4,"Bằng chứng kiểm thử và giới hạn xác nhận",
 ["Hạng mục","Kết quả được ghi nhận","Giới hạn diễn giải"],[
  ("Flutter test toàn dự án","250 bài kiểm tra PASS trong biên bản 04/11/2026","Không chạy lại trên trạng thái workspace hiện tại"),
  ("Phân tích tĩnh","No issues found trong biên bản","Không thay thế kiểm thử chức năng và thiết bị"),
  ("Firestore Emulator","PASS các nhóm quy tắc và transaction đã nêu","Emulator không phải Firebase production"),
  ("Khám phá / phân trang","70 bài kiểm tra trong tài liệu tính năng","Chỉ phản ánh phạm vi truy vấn và giao diện đã nêu"),
  ("Thiết bị thật, nhiều tài khoản","Chưa có bằng chứng hoàn tất toàn bộ luồng ba vai trò","Cần kiểm thử nghiệm thu trước khi vận hành thật"),
 ],[1.3,2.35,2.05],"Nguồn: docs/ROLE_SYNC_AUDIT.md và docs/DISCOVERY_PERFORMANCE.md [10], [12].")

# CHƯƠNG 5
heading("CHƯƠNG 5: KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN",1,True)
heading("5.1. KẾT QUẢ ĐẠT ĐƯỢC",2)
para("Đồ án đã hình thành một ứng dụng Flutter có tổ chức theo ba vai trò và gắn các nhóm chức năng chính của vòng đời thuê phòng. Người thuê có khu vực khám phá, yêu cầu xem và theo dõi nơi ở; chủ trọ có công cụ quản lý danh mục, hợp đồng, chi phí và sự cố; quản trị viên có các màn hình phục vụ kiểm duyệt và hỗ trợ.")
para("Về dữ liệu, ứng dụng dùng Firebase Authentication để xác định UID, Firestore để chia sẻ dữ liệu nghiệp vụ và SQLite để lưu cục bộ theo UID ở các nền tảng được cấu hình. Records gắn với ownerUid và tenantIds; truy cập được kiểm tra bằng Firestore Rules. Ảnh, chứng từ và các dịch vụ thuê bao được tách khỏi dữ liệu cốt lõi theo các tích hợp riêng. Thiết kế này tạo ranh giới tương đối rõ giữa thông tin tin đăng công khai, hồ sơ thuê và quyền quản trị.")
para("Các luồng lịch xem, hợp đồng, hóa đơn, thanh toán và sự cố đã có màn hình cùng cấu trúc trạng thái để hai bên theo dõi. Hóa đơn thể hiện các dòng chi phí; yêu cầu thanh toán cần quyết định của chủ trọ; QR không thay thế xác nhận ngân hàng. Tài liệu dự án ghi nhận bộ kiểm tra Flutter, phân tích tĩnh và Firestore Emulator đã chạy đạt ở các thời điểm cụ thể; phạm vi và giới hạn đã được trình bày tại Mục 4.3.")
para("Trong quá trình thực hiện, nhóm đã vận dụng được kiến thức về xây dựng ứng dụng đa nền tảng, thiết kế mô hình dữ liệu tài liệu, phân quyền theo tài nguyên và chuyển yêu cầu thành luồng giao diện. Sản phẩm có thể dùng làm nền để tiếp tục kiểm thử tại cơ sở nhà trọ và bổ sung nghiệp vụ dựa trên phản hồi thực.")
heading("5.2. HẠN CHẾ HIỆN TẠI",2)
para("Thứ nhất, phân tích hiện trạng chưa dựa trên phỏng vấn hoặc quan sát tại một nhà trọ cụ thể. Các giả định về kỳ thu tiền, cách tính dịch vụ, hồ sơ bàn giao và xử lý cọc cần được xác nhận với người dùng thật trước khi chốt quy trình.")
para("Thứ hai, một số nghiệp vụ cần quyết định của con người. Hợp đồng được ghi nhận và hiển thị nhưng chưa ký điện tử trong ứng dụng; thanh toán tiền thuê dựa vào QR và việc chủ trọ đối chiếu, không có xác nhận tự động từ ngân hàng. Webhook SePay hiện phục vụ nhánh thuê bao chủ trọ, không phải đối soát các hóa đơn thuê.")
para("Thứ ba, kiểm thử có bằng chứng trong repository chưa bao gồm một lượt nghiệm thu trọn vẹn trên thiết bị thật với ba tài khoản và dữ liệu cloud mới nhất. Cấu hình dịch vụ ngoài, thông báo đẩy, quyền tải tệp, lỗi mạng và xung đột cần kiểm tra lại theo môi trường phát hành. Tình trạng lưu cục bộ cũng không bảo đảm mọi tính năng đều hoạt động ngoại tuyến.")
para("Thứ tư, việc xác minh tin đăng chưa đồng nghĩa kiểm tra quyền sở hữu hay hồ sơ pháp lý. Quản trị viên có thể kiểm tra thông tin được cung cấp và trạng thái công khai, nhưng quyết định pháp lý cần quy trình xác minh riêng. Báo cáo cũng chưa đánh giá tải đồng thời lớn, khôi phục sau sự cố diện rộng hoặc tuân thủ một quy trình kiểm toán vận hành.")
para("Cuối cùng, mô hình SQLite hiện lưu một số dữ liệu dạng snapshot JSON, nên truy vấn báo cáo phức tạp và nâng cấp schema có thể tốn công hơn một mô hình được chuẩn hóa theo nghiệp vụ. Khi quy mô tăng, cần đo dung lượng, số lần đọc Firestore, chi phí ảnh và thời gian phản hồi thay vì chỉ dựa vào kiểm thử giao diện.")
heading("5.3. HƯỚNG PHÁT TRIỂN",2)
para("Giai đoạn tiếp theo nên bắt đầu bằng khảo sát tại một hoặc hai cơ sở nhà trọ với sự đồng ý của chủ cơ sở và người thuê. Nhóm cần ghi lại biểu mẫu đang dùng, cách tính giá, ngày chốt, thời gian xử lý sự cố, tình huống hoàn cọc và trường hợp thay đổi người ở. Kết quả sẽ giúp phân biệt quy trình bắt buộc với thói quen riêng của từng nơi.")
para("Sau khảo sát, ưu tiên chạy thử trọn vòng đời thuê trên thiết bị thật: người thuê gửi lịch, chủ trọ phản hồi, lập hợp đồng, ghi chỉ số, phát hành hóa đơn, gửi chứng từ và xác nhận; đồng thời thử luồng sự cố. Mỗi đợt chạy cần dùng tài khoản riêng, ghi nhận phiên bản ứng dụng, môi trường Firebase và kết quả đọc lại. Trước khi có người dùng thật cần rà soát Rules đã triển khai, backup/restore, log thao tác nhạy cảm, chính sách lưu tệp và hướng dẫn xử lý khi mạng gián đoạn.")
para("Về nghiệp vụ, có thể bổ sung biên bản bàn giao và trả phòng, phụ lục gia hạn, quy trình điều chỉnh hóa đơn, phí dịch vụ theo cấu hình linh hoạt và xuất báo cáo thu chi. Tích hợp ngân hàng cho tiền thuê chỉ nên thực hiện khi có cơ chế nhận webhook, đối soát mã giao dịch và xử lý giao dịch lặp; trạng thái phải được cập nhật từ nguồn xác nhận đáng tin cậy thay vì từ nội dung client gửi.")
para("Về trải nghiệm, cần cải thiện tìm kiếm theo địa chỉ, tiêu chí phù hợp và bản đồ, hỗ trợ thông báo có thể cấu hình theo từng loại sự kiện, nâng khả năng tiếp cận và theo dõi hiệu năng ở thiết bị cấu hình thấp. Phần quản trị nên có nhật ký không thể sửa tùy tiện cho các quyết định xác minh, khóa tài khoản và điều chỉnh dữ liệu tài chính.")
para("Về kỹ thuật, có thể tách repository và logic nghiệp vụ rõ hơn, chuẩn hóa schema cho báo cáo lớn, bổ sung kiểm thử Rules tự động trong quy trình build và thiết lập môi trường staging. Khi lưu nhiều giấy tờ cá nhân, cần rà soát thời hạn giữ dữ liệu, thu hồi quyền, xóa theo yêu cầu và quy trình phản ứng sự cố. Những thay đổi này nên được ưu tiên theo rủi ro thực tế và chi phí vận hành.")

heading("TÀI LIỆU THAM KHẢO",1,True)
refs=[
 "[1] Nhóm phát triển TroPremium, Mã nguồn ứng dụng và cấu hình dự án: thư mục lib/, backend/supabase/, firestore.rules, storage.rules và pubspec.yaml, đối chiếu ngày 22/11/2026.",
 "[2] Flutter, Flutter architectural overview, https://docs.flutter.dev/resources/architectural-overview, truy cập ngày 22/11/2026.",
 "[3] Firebase, Get started with Firebase in your Flutter project, https://firebase.google.com/docs/flutter/setup, truy cập ngày 22/11/2026.",
 "[4] Firebase, Cloud Firestore data model, https://firebase.google.com/docs/firestore/data-model, truy cập ngày 22/11/2026.",
 "[5] Firebase, Get started with Cloud Firestore Security Rules, https://firebase.google.com/docs/firestore/security/get-started, truy cập ngày 22/11/2026.",
 "[6] Firebase, Transactions and batched writes, https://firebase.google.com/docs/firestore/manage-data/transactions, truy cập ngày 22/11/2026.",
 "[7] Flutter packages, sqflite, https://pub.dev/packages/sqflite, truy cập ngày 22/11/2026.",
 "[8] Supabase, Edge Functions, https://supabase.com/docs/guides/functions, truy cập ngày 22/11/2026.",
 "[9] VietQR, API danh sách ngân hàng, https://www.vietqr.io/api-bank, truy cập ngày 22/11/2026.",
 "[10] Nhóm phát triển TroPremium, Kiểm tra đồng bộ ba vai trò, docs/ROLE_SYNC_AUDIT.md, biên bản ngày 04/11/2026.",
 "[11] Nhóm phát triển TroPremium, SePay, Cloudinary, Supabase và Firebase, docs/third-party-integrations.md, tài liệu tích hợp trong repository.",
 "[12] Nhóm phát triển TroPremium, Tối ưu trang Khám phá, docs/DISCOVERY_PERFORMANCE.md, tài liệu kiểm tra truy vấn và phân trang trong repository.",
 "[13] Nhóm phát triển TroPremium, Rà soát và cập nhật admin, docs/KIEM_TRA_ADMIN.md, tài liệu kiểm thử giao diện và nghiệp vụ trong repository.",
 "[14] Firebase, Understand Firebase Security Rules for Cloud Storage, https://firebase.google.com/docs/storage/security, truy cập ngày 22/11/2026.",
]
for item in refs:
    p=doc.add_paragraph(style="BaoCaoTaiLieu")
    set_run(p.add_run(item),12)

doc.core_properties.title="Báo cáo đồ án TroPremium – Ứng dụng quản lý nhà trọ"
doc.core_properties.subject="Phân tích, thiết kế, cài đặt và kiểm thử ứng dụng quản lý nhà trọ"
doc.core_properties.author="Nhóm thực hiện đồ án"
settings=doc.settings.element
upd=settings.find(qn("w:updateFields"))
if upd is None:
    upd=OxmlElement("w:updateFields"); settings.append(upd)
upd.set(qn("w:val"),"true")
for sec in doc.sections:
    sec.page_width=Cm(21); sec.page_height=Cm(29.7)
    sec.left_margin=Cm(3.5); sec.right_margin=Cm(2.5)
    sec.top_margin=Cm(2.5); sec.bottom_margin=Cm(2.5)
doc.save(str(OUT))
print("CREATED",OUT,"BYTES",OUT.stat().st_size,"SECTIONS",len(doc.sections),"PARAGRAPHS",len(doc.paragraphs),"TABLES",len(doc.tables))

def activity_png():
    im=Image.new("RGB",(1900,2480),"white"); d=ImageDraw.Draw(im)
    d.text((950,28),"LUỒNG TỪ TÌM PHÒNG ĐẾN THANH TOÁN",font=fnt(52,True),fill="black",anchor="ma")
    x0=40; lane=606; top=130; bottom=2380
    for i,label in enumerate(["NGƯỜI THUÊ","ỨNG DỤNG","CHỦ TRỌ"]):
        x=x0+i*lane
        d.rectangle((x,top,x+lane,bottom),outline="black",width=3)
        d.rectangle((x,top,x+lane,top+90),outline="black",width=3)
        d.text((x+lane/2,top+44),label,font=fnt(40,True),fill="black",anchor="mm")
    def box(lane_id,y,text,h=118):
        x1=x0+lane_id*lane+58; x2=x0+(lane_id+1)*lane-58
        rect=(x1,y-h/2,x2,y+h/2)
        d.rounded_rectangle(rect,radius=24,outline="black",width=4)
        centered(d,rect,text,fnt(36))
        return (x0+lane_id*lane+lane/2,y)
    cx=x0+lane/2
    d.ellipse((cx-22,238,cx+22,282),fill="black")
    points=[
      (0,350,"Tìm phòng theo khu vực, giá và nhu cầu"),
      (1,500,"Ứng dụng lọc dữ liệu, hiển thị phòng còn đăng"),
      (0,650,"Chọn phòng và gửi thời gian muốn xem"),
      (1,800,"Lưu yêu cầu, gắn người thuê và báo chủ trọ"),
      (2,950,"Chấp nhận, đề xuất giờ khác hoặc từ chối"),
      (0,1100,"Người thuê nhận kết quả và đi xem phòng"),
      (2,1250,"Hai bên thống nhất; chủ trọ lập hồ sơ thuê"),
      (2,1400,"Hai bên ký bản giấy; chủ trọ nhập thông tin"),
      (1,1550,"Lưu hợp đồng, thành viên và phạm vi dữ liệu"),
      (2,1700,"Đến kỳ, chủ trọ nhập chỉ số điện nước"),
      (1,1850,"Kiểm tra chỉ số, tạo hóa đơn theo đơn giá"),
      (0,2000,"Người thuê xem chi tiết và gửi minh chứng"),
      (2,2150,"Chủ trọ đối chiếu rồi duyệt hoặc từ chối"),
    ]
    coords=[box(*item) for item in points]
    arrow(d,(cx,282),(coords[0][0],points[0][1]-60))
    for i in range(len(coords)-1):
        arrow(d,(coords[i][0],points[i][1]+60),(coords[i+1][0],points[i+1][1]-60),width=4,head=14)
    dy=2290; dcx=x0+2*lane+lane/2
    diamond=[(dcx,dy-55),(dcx+80,dy),(dcx,dy+55),(dcx-80,dy)]
    d.polygon(diamond,outline="black",fill="white"); d.line(diamond+[diamond[0]],fill="black",width=4)
    centered(d,(dcx-70,dy-35,dcx+70,dy+35),"Đã khớp?",fnt(30,True))
    arrow(d,(coords[-1][0],points[-1][1]+60),(dcx,dy-55),width=4,head=14)
    d.text((dcx+105,dy-32),"Đúng: cập nhật số đã thu",font=fnt(30),fill="black")
    d.text((dcx+105,dy+18),"Chưa đúng: yêu cầu bổ sung",font=fnt(30),fill="black")
    d.text((950,2430),"Trong thời gian thuê, người thuê có thể báo sự cố; chủ trọ cập nhật xử lý và người thuê xác nhận hoặc mở lại yêu cầu.",font=fnt(29),fill="black",anchor="ms")
    out=BytesIO(); im.save(out,format="PNG",dpi=(300,300)); return out.getvalue()

def architecture_png():
    im=Image.new("RGB",(2100,1150),"white"); d=ImageDraw.Draw(im)
    d.text((1050,30),"KIẾN TRÚC TRIỂN KHAI VÀ CÁC KÊNH TÍCH HỢP",font=fnt(50,True),fill="black",anchor="ma")
    boxes={
      "ui":(65,190,560,500,"GIAO DIỆN FLUTTER\nNgười thuê • Chủ trọ\nQuản trị viên"),
      "app":(700,190,1260,500,"LỚP ỨNG DỤNG\nĐiều hướng theo vai trò\nStore • kiểm tra dữ liệu\nRepository"),
      "auth":(1450,150,2025,320,"FIREBASE AUTH\nPhiên đăng nhập\nHồ sơ vai trò users/{uid}"),
      "cloud":(1450,390,2025,650,"CLOUD FIRESTORE\nNhà • phòng • hợp đồng\nHóa đơn • thanh toán\nSự cố • lịch xem • tin nhắn"),
      "local":(700,700,1260,980,"SQLITE CỤC BỘ\nCache / dữ liệu theo UID\nAndroid • desktop"),
      "media":(65,700,560,980,"ẢNH VÀ TÀI LIỆU\nCloudinary\nKý upload và URL riêng\nqua Edge Function"),
      "subs":(1450,760,2025,990,"SUPABASE EDGE\nGói thuê bao chủ trọ\nWebhook SePay cho gói"),
      "external":(700,1030,1260,1120,"VietQR • Bản đồ • FCM"),
    }
    arrow(d,(560,345),(700,345)); arrow(d,(1260,260),(1450,235)); arrow(d,(1260,410),(1450,500))
    arrow(d,(980,500),(980,700)); arrow(d,(560,840),(700,840)); arrow(d,(1260,840),(1450,880)); arrow(d,(980,980),(980,1030),head=13)
    for key,(x1,y1,x2,y2,text) in boxes.items():
        d.rounded_rectangle((x1,y1,x2,y2),radius=22,outline="black",width=4,fill="white")
        centered(d,(x1+8,y1+8,x2-8,y2-8),text,fnt(34 if key not in ("external",) else 31,key in ("ui","app","auth","cloud","subs")))
    d.text((1050,1075),"Firestore là nguồn dữ liệu dùng chung; SQLite không thay thế quyền kiểm tra trên máy chủ.",font=fnt(29),fill="black",anchor="ms")
    out=BytesIO(); im.save(out,format="PNG",dpi=(300,300)); return out.getvalue()

def model_png():
    im=Image.new("RGB",(2150,1450),"white"); d=ImageDraw.Draw(im)
    d.text((1075,28),"MÔ HÌNH KHÁI NIỆM DỮ LIỆU NGHIỆP VỤ",font=fnt(50,True),fill="black",anchor="ma")
    nodes={
      "Nhà trọ":(60,150,470,390,["propertyId","ownerUid","published"]),
      "Phòng":(580,150,990,390,["roomId • propertyId","availability • price"]),
      "Hợp đồng":(1100,150,1510,390,["leaseId • roomId","tenantIds • term"]),
      "Thành viên":(1620,150,2030,390,["memberId • leaseId","tenantId • status"]),
      "Chỉ số":(580,520,990,760,["readingId • roomId","period • readings"]),
      "Hóa đơn":(1100,520,1510,760,["invoiceId • leaseId","lines • total • remaining"]),
      "Thanh toán":(1620,520,2030,760,["paymentId • invoiceId","status • proof reference"]),
      "Sự cố":(60,930,470,1170,["incidentId • roomId","reporterId • status"]),
      "Lịch xem":(580,930,990,1170,["viewingId • roomId","tenantId • startsAt"]),
      "Hội thoại":(1100,930,1510,1170,["conversationId","participants • messages"]),
    }
    arrow(d,(470,270),(580,270)); d.text((520,230),"1:N",font=fnt(27,True),fill="black",anchor="mm")
    arrow(d,(990,270),(1100,270)); d.text((1045,230),"1:N",font=fnt(27,True),fill="black",anchor="mm")
    arrow(d,(1510,270),(1620,270)); d.text((1565,230),"1:N",font=fnt(27,True),fill="black",anchor="mm")
    arrow(d,(990,640),(1100,640)); d.text((1045,600),"1:N",font=fnt(27,True),fill="black",anchor="mm")
    arrow(d,(1510,640),(1620,640)); d.text((1565,600),"1:N",font=fnt(27,True),fill="black",anchor="mm")
    arrow(d,(780,390),(780,520)); d.text((830,455),"ghi theo kỳ",font=fnt(26,True),fill="black")
    arrow(d,(1305,390),(1305,520)); d.text((1360,455),"phát sinh",font=fnt(26,True),fill="black")
    arrow(d,(265,390),(265,930)); d.text((310,670),"có sự cố",font=fnt(26,True),fill="black")
    arrow(d,(785,390),(785,930)); d.text((830,830),"đặt lịch",font=fnt(26,True),fill="black")
    arrow(d,(1305,390),(1305,930)); d.text((1355,835),"trao đổi",font=fnt(26,True),fill="black")
    for name,(x1,y1,x2,y2,attrs) in nodes.items():
        d.rectangle((x1,y1,x2,y2),outline="black",width=4,fill="white")
        d.rectangle((x1,y1,x2,y1+58),outline="black",width=3,fill=(235,235,235))
        d.text(((x1+x2)/2,y1+28),name,font=fnt(34,True),fill="black",anchor="mm")
        y=y1+84
        for item in attrs:
            d.text((x1+18,y),item,font=fnt(27),fill="black"); y+=42
    d.text((1075,1290),"Quan hệ nghiệp vụ ở mức khái niệm; Firestore lưu document, không triển khai thành các bảng SQL.",font=fnt(29),fill="black",anchor="ms")
    out=BytesIO(); im.save(out,format="PNG",dpi=(300,300)); return out.getvalue()
