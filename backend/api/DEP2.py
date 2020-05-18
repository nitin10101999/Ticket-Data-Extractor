
#!pip install pytesseract


#!pip install regex


import pytesseract
import os
import random
import regex as re
try:
    from PIL import Image
except ImportError:
    import Image


pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'


allowed_chars = ['.', ':', '/']


def clean_text(result):
    res = ""
    for i in range(len(result)):
        cnt = 0
        if(result[i].isalnum() == False):
          for j in allowed_chars:
            if(result[i] == j):
              cnt = cnt + 1
              break
          if(cnt < 1):
            res += ' '
          else:
            res += result[i]
        else:
          res += result[i]
    return res




def clean_price(i):
    falg = 0
    for j in range(len(i)):
      if(i[j]=='.'):
        flag = 1
        break
    prc = (i[:j])

    return prc



def most_frequent(List): 
    return max(set(List), key = List.count)



def _regex(result):

    FromTo_data = ''
    date_data = ''
    time_data = ''
    FromTo = re.search(r'([a-z]|[A-Z]|[0-9])+(.*)[t|T][o|O|0](.*)([a-z]|[A-Z]|[0-9])+', result)
    if FromTo:
        ansFromTo = clean_text(FromTo.group())
        FromTo_data = ansFromTo
        #ansFromTo = searchInDB(ansFromTo)
        print("FromTo : ", ansFromTo)

        
        
    date =  re.search(r'[0-3]{0,1}[0-9]/[0-1]{0,1}[0-9]/[0-9]{0,1}[0-9]{0,1}[0-9]{0,1}[0-9]', result)
    if date:
        date_data = date.group()
        print("date : ", date.group())

        
        
    time = re.search(r'[0-2]{0,1}[0-9](:[0-5]{0,1}[0-9])+', result)
    if time:
        time_data = time.group()
        print("time : ", time.group())

        
        
    per_h_price = 0
    net_rate = 0
    total_travellers = 0
    per_head_price = re.search(r'([0-9]+)(.*?)([x|X|\*| ])(.*?)([0-9]+\.[0-9]+)', result)   
    total_price = re.findall(r'([0-9]+\.[0-9]+)', result)
    net_price = []
    for i in range(len(total_price)):
        net_price.append(clean_price(total_price[i]))
    if len(net_price) > 0 :
        net_rate =  most_frequent(net_price)
        print("net_price : ", net_rate)
    
    if per_head_price and net_rate!=0 :
        per_h_price = clean_price(per_head_price.group(5))
        total_travellers = per_head_price.group(1)
        if( int(net_rate) == (int(total_travellers) * int(per_h_price)) ):
            print("total_travellers : ", total_travellers)
            print("per_head_price : ", per_h_price)
        else:
            print("net_price output is not confident")
    data = {
        'FromTo': FromTo_data,
        'date' : date_data,
        'time' : time_data,
        'PerHeadPrice' : per_h_price,
        'total_travellers' : total_travellers,
        'total_price' : net_rate
    }
    return data




"""result = pytesseract.image_to_string(Image.open('data.jpg'))
#print(result)
ans = _regex(result)
print(type(ans))"""