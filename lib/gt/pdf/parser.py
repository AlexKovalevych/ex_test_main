import PyPDF2


def parse(path):
    pdf_obj = open(path, 'rb')
    reader = PyPDF2.PdfFileReader(pdf_obj)
    return list(map(lambda i: get_page_text(reader.getPage(i)), range(0, reader.numPages)))


def get_page_text(page):
    return page.extractText()
