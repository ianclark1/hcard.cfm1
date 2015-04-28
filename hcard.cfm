<!---
	Name : cfhcard
	Author : Justin Mclean
	Copyright : Class Software 2007 (http://www.classsoftware.com)
	License : Licensed under Creative Commons attribution license
--->
<cfif thisTag.executionMode is "end">
<cfscript>
	// regular expessions and strings
	newline = chr(13) & chr(10);
	newlinecomma = '#newline#,'; 
	city = '[A-Z|a-z| ]+';
	state = '[A-Z]{2,3}'; // aus 3 us 2
	postcode = '[0-9|\-]{4,10}$'; // aus/nz 4 us 5(-4)
	country = '[A-Z]+[a-z]*';
	
	// function to take an address string and break it up into it's elements
	function parseAddress(addressstring)
	{
		var nolines = 0;
		var lastline = '';
		var line = '';
		var address = structnew();
		
		// split address on commas and new lines
		if (find(',', addressstring) or find(newline,addressstring)) {
			nolines = listlen(addressstring, newlinecomma);
			
			address.address = listfirst(addressstring, newlinecomma);
			lastaddress = '';
			
			// try and find state postcode line
			for (i = 2; i lte nolines; i = i + 1) {
				line = trim(listgetat(addressstring, i, newlinecomma));
				lastline = trim(listgetat(addressstring, i-1, newlinecomma));
			
				// look for line matching state and postcode 
				if (refind('#city# #state# #postcode#',line)) {
					address.city = trim(listfirst(line, ' '));
					address.state = trim(listgetat(line, 2, ' '));
					address.postcode = trim(listlast(line, ' '));
					break;
				}
				// look for line matching state and postcode	
				else if (refind('#state# #postcode#',line)) {
				address.address = lastaddress;
					address.city = trim(lastline);
					address.state = trim(listfirst(line, ' '));				
					address.postcode = trim(listlast(line, ' '));
					break;
				}
				// look for line matching city and postcode (NZ)	 
				else if (refind('#city# #postcode#',line)) {
					address.city = trim(listfirst(line, ' '));
					address.postcode = trim(listlast(line, ' '));
					break;
				}
				// look for line matching postcode (NZ)
				else if (refind('#postcode#',line)) {
					address.address = lastaddress;
					address.city = trim(lastline);
					address.postcode = trim(line);
					break;
				}								
				else {
					if (not isdefined('address.organisation')) {
						address.organisation = trim(lastline);
					}
					lastaddress =  address.address;
					address.address = trim(line);
				}
			}
			
			if (isdefined('address.organisation') and address.organisation is address.address) {
				structdelete(address, 'organisation');
			}
			
			// check for country if we still have lines to go
			if (i lt nolines) {
				line = trim(listgetat(addressstring, i+1, newlinecomma));
				if (refind('#country#$',line)) {
					address.country = line;
				}			
			}
		}
			
		return address;
	}
	</cfscript>
	
	<cfset content = thisTag.GeneratedContent>

	<cfscript>
		// find address lines assume they come first
		content = replace(content, ',', newline, 'ALL');
		endaddress = 0;
		address = structnew();
		addressstr = '';

		nolines = listlen(content, newline);
		for (i=2; i lte nolines; i = i + 1) {
			line = trim(listgetat(content, i, newline));
			addressstr = '#addressstr##line##newline#';
				
			// look for (city) state postcode line
			if (refind('#state# #postcode#$', line) or refind('#city# #state# #postcode#', line)) {
				endaddress = i;
				break;
			}
		}
	
		// check if next line could be country
		if (endaddress lt nolines) {
			line = listgetat(content, endaddress + 1, newline);
			if (refind('#country#$', line)) {
				addressstr = '#addressstr##line##newline#';
				endaddress = endaddress + 1;
			}
		}
		// parse address
		address = parseAddress(addressstr);
		
		// set other address fields
		address.name = listfirst(content, newline);
		
		// check other lines after address for other known values (eg phone or email)
		for (i = endaddress + 1; i lte nolines; i = i + 1) {
			line = trim(listgetat(content, i, newline));

			if (refind('[A-Z|a-z]+[\:|\-| ]+[0-9|\-|\+|\(|\)| ]+$',line)) {
				label = trim(listfirst(line, ':-'));
				if (lcase(label) is 'mobile' or lcase(label) is 'm') {
					address.mobile = trim(listlast(line, ':-'));
				}
				if (lcase(label) is 'phone' or lcase(label) is 'telephone' or lcase(label) is 'work' or lcase(label) is 'p' or lcase(label) is 't' or lcase(label) is 'w') {
					address.phone = trim(listlast(line, ':-'));
				}				
			}
			else if (refind('[0-9|\-|\+\(|\)| ]+$',line)) {
				address.phone = line;
			}
			else if (refind('[A-Z|a-z]+[\:|\-| ]+[A-Z|a-z|0-9]+\@[A-Z|a-z|0-9|\.]+$', line)) {
				label = listfirst(line, ':-');
				if (lcase(label) is 'email') {
					address.email = trim(listlast(line, ':-'));
				}
			}
			else if (refind('[A-Z|a-z|0-9]+\@[A-Z|a-z|0-9|\.]+$', line)) {
				address.email = line;
			}			
		}
	</cfscript>
	
	<cfsavecontent variable="hcard">
<cfoutput>
<div class="vcard">
	<div class="fn">#address.name#</div>
	<cfif isdefined("address.organisation") and isdefined("address.department")><div class="org"><span class="organization-name">#address.organisation#</span> <span class="organization-uni">#address.department#</span></div>
	<cfelseif isdefined("address.organisation")><div class="org">#address.organisation#</div></cfif>
	<div class="adr"><span class="street-address">#address.address#</span>, <span class="locality">#address.city#</span><cfif isdefined("address.state")> <span class="region">#address.state#</span></cfif> <span class="postal-code">#address.postcode#</span><cfif isdefined("address.country")> <span class="country-name">#address.country#</span></cfif></div>
	<cfif isdefined("address.phone")><div class="tel"><span class="type"><abbr title="work">Phone:</abbr></span> <span class="value">#address.phone#</span></div></cfif>
	<cfif isdefined("address.mobile")><div class="tel"><span class="type"><abbr title="cell">Mobile:</abbr></span> <span class="value">#address.mobile#</span></div></cfif>
	<cfif isdefined("address.email")><div>Email: <a class="email" href="mailto:#address.email#">#address.email#</a></div></cfif>
</div>
</cfoutput>
	</cfsavecontent>
		
	<cfset thisTag.GeneratedContent = hcard>
</cfif>