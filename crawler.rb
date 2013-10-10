#coding:utf-8
require 'open-uri'
require 'nokogiri'
require './models.rb'

SFC_TIME = [ nil, [9,25],[11,10],[13,00],[14,45],[16,30],[18,10]]

def japanese_2_time d_s , pr
  matched = d_s.match(/(\d{1,2})月\s*(\d{1,2})日/)
  if !matched
    return nil
  end
  month = matched[1].to_i
  day = matched[2].to_i
  year = Time.now.year
  year += 1 if month < Time.now.month
  return Time.local(year,month,day,SFC_TIME[pr.to_i][0],SFC_TIME[pr.to_i][1])
end

def each_tr tr,uri
  tds = tr.css('td')
  if tds.length == 0 
    return nil
  end
  ret = {}
  ret[:time] = japanese_2_time(tds[0].text,tds[1].text.to_i)
  ret[:period] = tds[1].text.to_i
  ret[:subject] = tds[2].text.to_s
  instructors = []
  tds[3].children.each {|i| instructors << i.text if i.text.length > 0}
  ret[:instructor] = instructors.map{|s|s.split(/[\s　]/).join(' ')}.join(',')
  if tds[4].css('a').length > 0
    h = tds[4].css('a').first.attributes['href'].value.to_s
    ret[:syllabus] = (uri + h).to_s
    ret[:id] = h.match(/&lecture=([\d\.]+)/)[1].to_i
  else
    return nil
    ret[:syllabus] = ''
  end
  if /抽選([\d\.]+)倍/ =~ tds[5].text then
    ret[:lot] = true
    ret[:odds] = $1.to_f
    ret[:rest] = 0
  else
    ret[:lot] = false
    ret[:odds] = 0 
    ret[:rest] = tds[5].text.to_i
  end
  return ret
end

def get_list
  uri = URI('https://wellness.sfc.keio.ac.jp/v3/')
  doc = Nokogiri::HTML(open(uri))
  doc.css('a').each do |a|
    if a.text == '2週間分の予約空き授業を全て表示'
      uri = uri + a.attributes['href'].value
      doc = Nokogiri::HTML(open(uri))
      break
    end
  end
  return [doc.css('table.cool'),uri]
end

(list,uri) = get_list
list.css('tr').each do |e|
  d = each_tr(e,uri)
  if !d
    next 
  end
  m = nil
  if m = Lectures.find(:id=>d[:id])
    m.update(d)
  else
    Lectures.create(d)
  end
end
