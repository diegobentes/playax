require 'pdf-reader'

class PdfEcadImporter
  CATEGORIES = { 'CA' => 'Author', 'E' => 'Publisher', 'V' => 'Versionist', 'SE' => 'SubPublisher' }

  def initialize(pdf_file_path)
    @pdf = PDF::Reader.new(pdf_file_path)
  end

  def self.right_holder(line)
    share_and_role = line.match(/[A-Z]*\s{1,3}[0-9]*,[0-9]*/).to_s.split(" ")
    return nil unless share_and_role[1]
    society_name_and_ipi = line.match(/[0-9]{3}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2} [A-Z]*/).to_s.split(" ")

    name = line[12,37].strip
    society_name = society_name_and_ipi[1]
    pseudo_name = line[49,25].strip.match(/^[A-Z\s]*/).to_s.strip
    source_name = "Ecad"
    source_id = line.match(/^[0-9]{1,20}/).to_s.strip
    ipi = society_name_and_ipi[0] ? society_name_and_ipi[0].gsub(".","") : society_name_and_ipi[0]
    share = share_and_role[1].gsub(",",".").to_f
    role = CATEGORIES[share_and_role[0]]
    
    return {
      name: name,
      society_name: society_name,
      pseudos: [
        {
          name: pseudo_name,
          main: true
        }
      ],
      external_ids: [
        {
          source_name: source_name,
          source_id: source_id
        }
      ],
      ipi: ipi,
      share: share,
      role: role
    }
  end

  def self.work(line)
    source_id = line.match(/^[0-9]{1,20}/).to_s.strip
    iswc = line.match(/[T|-]+[[0-9]| ]+.[[0-9]| ]+.[[0-9]| ]+[-|-[0-9]]+/).to_s.strip
    title = line[33,60].strip
    situation = line.match(/ LB[\w*\/]+ | LB /).to_s.strip
    created_at = line.match(/(0[1-9]|[12][0-9]|3[01])\/(0[1-9]|1[012])\/[12][0-9]{3}/).to_s.strip

    return {
      iswc: iswc, 
      title: title, 
      external_ids: [
        {
          source_name: 'Ecad',
          source_id: source_id
        }
      ],
      situation: situation,
      created_at: created_at
    }
  end

  def works
    final_hash = []
    right_holder_irregular_line_control = false
    right_holder_irregular_line_content = ""

    @pdf.pages.each do |page|
      page.text.each_line do |line|
        if line.match(/ [T| ]-+/)
          final_hash << self.class.work(line)
        else
          if line.match(/^[0-9]{3,20}/) or right_holder_irregular_line_control then
            if line.match(/[0-9]*\,[0-9]*/) then
              if right_holder_irregular_line_control then
                line = right_holder_irregular_line_content + line
                right_holder_irregular_line_control = false
                right_holder_irregular_line_content = ""
              end
              work = final_hash.last
              if work[:right_holders].kind_of?(Array)
                  work[:right_holders] << self.class.right_holder(line)
              else
                  work[:right_holders] = [self.class.right_holder(line)]
              end              
            else
              right_holder_irregular_line_control = true
              right_holder_irregular_line_content = line
              next
            end
          end
        end        
      end
    end
    return final_hash
  end

end