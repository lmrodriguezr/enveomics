
#
# @author: Luis M. Rodriguez-R
# @license: artistic license 2.0
#

require "enveomics_rb/enveomics"
use "restclient"
use "json"

class RemoteData
  # Class-level variables
  @@EUTILS = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
  @@EBIREST = "http://www.ebi.ac.uk/Tools"
   
  # Class-level methods
  def self.eutils(script, params={}, outfile=nil)
    response = nil
    10.times do
      begin
        response = RestClient.get "#{@@EUTILS}/#{script}", {:params=>params}
      rescue => err
        warn "Request failed #{response.nil? ? "without error code" :
          "with error code #{response.code}"}."
        next
      end
      break if response.code == 200
    end
    abort "Unable to reach NCBI EUtils, error code #{response.code}." unless
      response.code == 200
    unless outfile.nil?
      ohf = File.open(outfile, "w")
      ohf.print response.to_s
      ohf.close
    end
    response.to_s
  end
  def self.efetch(*etc)
    eutils "efetch.fcgi", *etc
  end
  def self.elink(*etc)
    eutils "elink.fcgi", *etc
  end
  def self.esummary(*etc)
    eutils "esummary.fcgi", *etc
  end
  def self.update_gi(db, old_gi)
    summ = JSON.parse RemoteData.esummary({:db=>db, :id=>old_gi,
      :retmode=>"json"})
    return nil,nil if summ["result"].nil? or summ["result"][old_gi.to_s].nil?
    new_acc = summ["result"][old_gi.to_s]["replacedby"]
    new_gi = (new_acc.nil? ? nil :
      RemoteData.efetch({:db=>db, :id=>new_acc, :rettype=>"gi"}))
    return new_gi,summ["result"][old_gi.to_s]["status"]
  end
  def self.ebiFetch(db, id, format, outfile=nil)
    url = "#{@@EBIREST}/dbfetch/dbfetch/#{db}/#{id}/#{format}"
    response = RestClient::Request.execute(:method=>:get,
      :url=>url, :timeout=>600)
    raise "Unable to reach EBI REST client, error code " +
      response.code.to_s + "." unless response.code == 200
    response.to_s
  end
  def self.ebiseq2taxid(id,db)
    doc = RemoteData.ebiFetch(db, id, "annot").split(/[\n\r]/)
    ln = doc.grep(/^FT\s+\/db_xref="taxon:/).first
    ln = doc.grep(/^OX\s+NCBI_TaxID=/).first if ln.nil?
    return nil if ln.nil?
    ln.sub!(/.*(?:"taxon:|NCBI_TaxID=)(\d+)["; ].*/, "\\1")
    return nil unless ln =~ /^\d+$/
    ln
  end
end

