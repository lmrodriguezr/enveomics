
#
# @author: Luis M. Rodriguez-R
# @update: Sep-29-2015
# @license: artistic license 2.0
#

require "enveomics_rb/enveomics"
use "restclient"

class RemoteData
   # Class-level variables
   @@EUTILS = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils"
   @@EBIREST = "http://www.ebi.ac.uk/Tools"
   
   # Class-level methods
   def self.eutils(script, params={}, outfile=nil)
      response = nil
      (1 .. 5).each do |i|
	 response = RestClient.get "#{@@EUTILS}/#{script}", {:params=>params}
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
   def self.ebiFetch(db, id, format, outfile=nil)
      url = "#{@@EBIREST}/dbfetch/dbfetch/#{db}/#{id}/#{format}"
      response = RestClient::Request.execute(:method=>:get,
	 :url=>url, :timeout=>600)
      raise "Unable to reach EBI REST client, error code " +
	 response.code.to_s + "." unless response.code == 200
      response.to_s
   end
end

