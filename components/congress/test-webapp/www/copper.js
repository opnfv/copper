/*
 Copyright 2015-2016 AT&T Intellectual Property, Inc
  
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
  
 http://www.apache.org/licenses/LICENSE-2.0
  
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/
var origin = "http://localhost:2257/proxy/?~url=";
var dataSources = [];
var datasource_tables = [];
var datasource_rows = [];
var policies = [];
var policy_tables = [];
var policy_rows = [];
var policy_rules = [];
var translators = [];

function get_dataSources() {
	dse = document.getElementById('dataSources');
	while (dse.firstChild) dse.removeChild(dse.firstChild);
	asyncXHR('GET',origin+'/v1/data-sources',function(xhr) {
		obj = JSON.parse(xhr.responseText);
		dataSources = obj.results;
		var str = '';
		for (i in dataSources) {
			datasource = dataSources[i].name;
			dhe = element('button',"datasources:"+datasource,datasource,1);
			de = element('div',"datasource:"+datasource,"",1);
			dhe.setAttribute('onclick','toggle("'+de.id+'");');
			dse.appendChild(dhe);
			de.style.display = 'none'
			for (j in dataSources[i]) {
				if (typeof dataSources[i][j] == 'object' && dataSources[i][j] != null) {
					oe = element('button',"",j,2);
					ae = element('table',"datasource:"+datasource+':'+j,null,2);
					ae.style.display = 'none'
					oe.setAttribute('onclick','toggle("'+ae.id+'");');
					de.appendChild(oe);
  		    ah = element('thead',"",null,null);
  		    ar = element('tr',"",null,null);
					for (k in dataSources[i][j]) {
						ahe = element('th',"",k,3);
						ah.appendChild(ahe);
						are = element('td',"",dataSources[i][j][k],3);
						ar.appendChild(are);
					}
					ae.appendChild(ah);						
					ae.appendChild(ar);						
				}
				else ae = element('p',"",j+':'+dataSources[i][j],2);
				de.appendChild(ae);
			}
			dsb = element('button',"",'Tables',2);
			dsb.setAttribute('onclick','get_datasource_tables('+i+');');
			de.appendChild(dsb);
			dst = element('p',"datasource:"+datasource+':tables',"",2);
			de.appendChild(dst);
			dse.appendChild(de);
			}
	},null,null,null);
}

function get_datasource_tables(dsIndex) {
	dsid = dataSources[dsIndex].id;
	datasource = dataSources[dsIndex].name;
	tb = document.getElementById("datasource:"+datasource+":tables");
	if (tb.innerHTML != "" && tb.style.display != 'none') tb.style.display = 'none';
	else {
		while (tb.firstChild) tb.removeChild(tb.firstChild);
		asyncXHR('GET',origin+'/v1/data-sources/'+dsid+'/tables',function(xhr) {
			obj = JSON.parse(xhr.responseText);
			if (obj.results.length == 0) {
				datasource_tables[dsIndex] = [];
				datasource_rows[dsIndex] = [];
				tb.innerHTML = "No tables defined.";
			}
			else {
				datasource_tables[dsIndex] = obj.results;
				datasource_rows[dsIndex] = [];
				for (i in datasource_tables[dsIndex]) {
					datasource_rows[dsIndex][i] = [];
					tid = datasource_tables[dsIndex][i].id;
					tbb = element('button',"datasource:"+datasource+":tables:"+tid+":get",tid,3);
					tbb.setAttribute('onclick','get_datasource_table_rows('+dsIndex+','+i+');');
					tb.appendChild(tbb);
					tbnr = element('span',"datasource:"+datasource+":tables:"+tid+":numrows","",null);
					tb.appendChild(tbnr);
					tbd = element('div',"datasource:"+datasource+":tables:"+tid,"",2);
					tb.appendChild(tbd);
				}
			}
			tb.style.display = 'block';
		},null,null,null);	
	}
}

function get_datasource_table_rows(dsIndex,tableIndex) {
	datasource = dataSources[dsIndex].name;
	dsid = dataSources[dsIndex].id;
	tid = datasource_tables[dsIndex][tableIndex].id;
  tbd = document.getElementById("datasource:"+datasource+":tables:"+tid);
	if (tbd.innerHTML != "" && tbd.style.display != 'none') tbd.style.display = 'none';
	else {
		while (tbd.firstChild) tbd.removeChild(tbd.firstChild);	
		asyncXHR('GET',origin+'/v1/data-sources/'+dsid+'/tables/'+tid+'/rows',function(xhr) {
			obj = JSON.parse(xhr.responseText);
			if (obj.results.length == 0) datasource_rows[dsIndex][tableIndex] = [];
			else datasource_rows[dsIndex][tableIndex] = obj.results;

			tbnr = document.getElementById("datasource:"+datasource+":tables:"+tid+":numrows");
			tbnr.innerHTML = " ("+obj.results.length+" rows)<br/>";

      tbr = element('table',"",null,0);
      tbh = element('thead',"",null,null);
			for (i in TRANSLATORS[datasource]) {
				if (tid == TRANSLATORS[datasource][i]['table-name']) {
          tbhr = element('tr',"",null,null);
					if (TRANSLATORS[datasource][i]['translation-type'] == 'LIST') {
						for (j in datasource_rows[dsIndex][tableIndex][0].data) {
							tbhd = element('th',"",null,null);
							tbhd.innerHTML = TRANSLATORS[datasource][i]['val-col'];
							tbhr.appendChild(tbhd);
						}
					}
					else {
						for (j in TRANSLATORS[datasource][i]['field-translators']) {
							tbhd = element('th',"",null,null);
							tbhd.innerHTML = TRANSLATORS[datasource][i]['field-translators'][j]['fieldname'];
							tbhd.title = TRANSLATORS[datasource][i]['field-translators'][j]['fieldname'];
							tbhr.appendChild(tbhd);
						}
					}
				tbh.appendChild(tbhr);
				}
			tbr.appendChild(tbh);
			}
			if (obj.results.length > 0) {
				datasource_rows[dsIndex][tableIndex] = obj.results;
				for (i in datasource_rows[dsIndex][tableIndex]) {
          tbrr = element('tr',"",null,null);
					data = datasource_rows[dsIndex][tableIndex][i].data;
					for (j in data) {
						tbrd = element('td',"",null,null);
  					tbrd.innerHTML = data[j];
  					tbrd.title = data[j];
						tbrr.appendChild(tbrd);
          }
				tbr.appendChild(tbrr);
				}
			tbd.appendChild(tbr);
			}
		tbd.style.display = 'block';
		},null,null,null);	
	}
}

function get_policies() {
	poe = document.getElementById('policies');
	while (poe.firstChild) poe.removeChild(poe.firstChild);
	asyncXHR('GET',origin+'/v1/policies',function(xhr) {
		obj = JSON.parse(xhr.responseText);
		policies = obj.results;
		for (i in policies) {
			policy = policies[i].name;
			he = element('button',"",policy,1);
			pe = element('div',"policies:"+policy,"",1);
			he.setAttribute('onclick','toggle("'+pe.id+'");');
			poe.appendChild(he);
			pe.style.display = 'none'
			for (j in policies[i]) {
				ae = element('p',"",j+':'+policies[i][j],2);
				pe.appendChild(ae);
			}
			rb = element('button',"",'Rules',2);
			rb.setAttribute('onclick','get_rules('+i+');');
			pe.appendChild(rb);
			pr = element('p',policy+':rules',"",2);
			pe.appendChild(pr);
			pob = element('button',"",'Tables',2);
			pob.setAttribute('onclick','get_policy_tables('+i+');');
			pe.appendChild(pob);
			pot = element('p',"policies:"+policy+':tables',"",2);
			pe.appendChild(pot);
			poe.appendChild(pe);
//			{"kind":"nonrecursive","description":"default action policy","name":"action","abbreviation":"actio",
//			"id":"29196084-604d-4964-93e6-c23eb2c52990","owner_id":"user"}
			}
	},null,null,null);
//	document.getElementById('response').innerHTML = dumpProps(policies,'policies',false);
}

/* Example of a 1-rule array response
{
  "results": [
    {
      "comment": "", 
      "id": "056a00a3-d5a7-46c5-8a40-d02e3f72ef03", 
      "rule": "samegroup(user1, user2) :- ldap:group(user1, g), ldap:group(user2, g)", 
      "name": null
    }
  ]
}
 */http://congress.readthedocs.org/en/latest/api.html

function get_policy_tables(policyIndex) {
	pid = policies[policyIndex].id;
	policy = policies[policyIndex].name;
	tb = document.getElementById("policies:"+policy+':tables');
	if (tb.innerHTML != "" && tb.style.display != 'none') tb.style.display = 'none';
	else {
		while (tb.firstChild) tb.removeChild(tb.firstChild);
// TODO: verify why http://congress.readthedocs.org/en/latest/api.html uses policy name
		asyncXHR('GET',origin+'/v1/policies/'+policy+'/tables',function(xhr) {
			obj = JSON.parse(xhr.responseText);
			if (obj.results.length == 0) {
				policy_tables[policyIndex] = [];
				policy_rows[policyIndex] = [];
				tb.innerHTML = "No tables defined.";
			}
			else {
				policy_tables[policyIndex] = obj.results;
				policy_rows[policyIndex] = [];
				for (i in policy_tables[policyIndex]) {
					policy_rows[policyIndex][i] = [];
					tid = policy_tables[policyIndex][i].id;
					tbb = element('button',"policies:"+policy+":tables:"+tid+":get",tid,3);
					tbb.setAttribute('onclick','get_policy_table_rows('+policyIndex+','+i+');');
					tb.appendChild(tbb);
					tbnr = element('span',"policies:"+policy+":tables:"+tid+":numrows","",null);
					tb.appendChild(tbnr);
					tbd = element('div',"policies:"+policy+":tables:"+tid,"",2);
					tb.appendChild(tbd);
				}
			}
			tb.style.display = 'block';
		},null,null,null);	
	}
}

function get_policy_table_rows(policyIndex,tableIndex) {
	policy = policies[policyIndex].name;
	pid = policies[policyIndex].id;
	tid = policy_tables[policyIndex][tableIndex].id;
	name = policy_tables[policyIndex][tableIndex].name;
	tbd = document.getElementById("policies:"+policy+":tables:"+tid);
	if (tbd.innerHTML != "" && tbd.style.display != 'none') tbd.style.display = 'none';
	else {
		while (tbd.firstChild) tbd.removeChild(tbd.firstChild);	
// TODO: Verify why policy name is used instead of policy ID
		asyncXHR('GET',origin+'/v1/policies/'+policy+'/tables/'+tid+'/rows',function(xhr) {
			obj = JSON.parse(xhr.responseText);
			if (obj.results.length == 0) policy_rows[policyIndex][tableIndex] = [];
			else policy_rows[policyIndex][tableIndex] = obj.results;

			tbnr = document.getElementById("policies:"+policy+":tables:"+tid+":numrows");
			tbnr.innerHTML = " ("+obj.results.length+" rows)<br/>";
      tbr = element('table',"",null,0);
      tbh = element('thead',"",null,null);
			tbr.appendChild(tbh);
/*
      tbh = element('thead',"",null,null);
			for (i in TRANSLATORS[policy]) {
				if (tid == TRANSLATORS[policy][i]['table-name']) {
          tbr = element('tr',"",null,null);
					if (TRANSLATORS[policy][i]['translation-type'] == 'LIST') {
						for (j in policy_rows[policyIndex][tableIndex][0].data) {
							tbd = element('th',"",null,null);
							tbd.innerHTML = TRANSLATORS[policy][i]['val-col'];
							tbr.appendChild(tbd);
						}
					}
					else {
						for (j in TRANSLATORS[policy][i]['field-translators']) {
							tbd = element('th',"",null,null);
							tbd.title = TRANSLATORS[policy][i]['field-translators'][j]['fieldname'];
							tbd.innerHTML = TRANSLATORS[policy][i]['field-translators'][j]['fieldname'];
							tbr.appendChild(tbd);
						}
					}
				tbh.appendChild(tbr);
				}
			tbe.appendChild(tbh);
			}
*/
			if (obj.results.length > 0) {
				policy_rows[policyIndex][tableIndex] = obj.results;
				for (i in policy_rows[policyIndex][tableIndex]) {
          tbrr = element('tr',"",null,null);
					data = policy_rows[policyIndex][tableIndex][i].data;
					for (j in data) {
						tbrd = element('td',"",null,null);
  					tbrd.innerHTML = data[j];
						tbrr.appendChild(tbrd);
          }
				tbr.appendChild(tbrr);
				}
			tbd.appendChild(tbr);
			}
		tbd.style.display = 'block';
		},null,null,null);	
	}
}

function get_rules(policyIndex) {
	policy = policies[policyIndex].name;
	pid = policies[policyIndex].id;
	pr = document.getElementById(policy+':rules');
	while (pr.firstChild) pr.removeChild(pr.firstChild);	
	asyncXHR('GET',origin+'/v1/policies/'+policy+'/rules',function(xhr) {
		obj = JSON.parse(xhr.responseText);
		policy_rules[policyIndex] = obj.results;
		if (obj.results.length == 0) {
			policy_rules[policyIndex] = [];
			pr.innerHTML = "No rules defined.";
		}
		else {
			var str = '';
//			alert(JSON.stringify(policy_rules[policyIndex]));
			for (i in policy_rules[policyIndex]) {
				name = policy_rules[policyIndex][i].name;
				he = element('button',name,name,3);
				re = element('div',name+"json","",4);
				he.setAttribute('onclick','toggle("'+re.id+'");');
				pr.appendChild(he);
				de = element('button',"","delete",null);
				de.setAttribute('onclick','delete_rule('+policyIndex+','+i+');');
				pr.appendChild(de);
				re.style.display = 'none';
				for (j in policy_rules[policyIndex][i]) {
					ae = element('p',"",j+':'+policy_rules[policyIndex][i][j],4);
					re.appendChild(ae);
				}
				pr.appendChild(re);
			}
		}
		cre = element('button',"cre","Create rule",3);
		cre.setAttribute('onclick','create_rule_input('+policyIndex+');');
		pr.appendChild(cre);
	},null,null,null);	
}

function create_rule_input(policyIndex) {
	pr = document.getElementById(policy+':rules');
	cre = document.getElementById('cre');
	/*
	 * Example: 
	error :- nova:vm(vm), neutron:network(network), nova:network(vm, network), -neutron:public(network), neutron:private(network), nova:owner(vm, vm-own), neutron:owner(network, net-own), -same-group(vm-own, net-own)
	samegroup(user1, user2) :- ldap:group(user1, g), ldap:group(user2, g)
	 */
	nrn = element('input',"nrn","Name",3);
	nrc = element('input',"nrc","Comment",3);
	rte = element('textarea',"nrule",null,3);
	pr.appendChild(nrn);
	pr.appendChild(nrc);
	pr.appendChild(rte);	
	cre.setAttribute('onclick','create_rule('+policyIndex+');');
}

function create_rule(policyIndex,name,comment,rule) {
	// use policy name rather than id as the id!
	policy = policies[policyIndex].name;
	name = document.getElementById("nrn").value;
	comment = document.getElementById("nrc").value;
	rule = document.getElementById("nrule").value;
	rid = guidGenerator();
	body = '{"id":"'+rid+'","name":"'+name+'","comment":"'+comment+'","rule":"'+rule+'"}'; 
	asyncXHR('POST',origin+'/v1/policies/'+policy+'/rules',function(xhr) {
		obj = JSON.parse(xhr.responseText);
		if (obj.error !== undefined) alert(xhr.responseText);
		// BUG: Congress creates rules asyncchronously, thus a query for rules immediately after rule creation may not return the newly created rule
		else setTimeout('get_rules('+policyIndex+');',1000);
	},null,"application/json",body);
}

/*
 * Deleting a rule takes the ID as resource path element, and returns a JSON copy of the rule deleted
 */
function delete_rule(policyIndex,ruleIndex) {
	policy = policies[policyIndex].name;
	name = policy_rules[policyIndex][ruleIndex].name;
	id = policy_rules[policyIndex][ruleIndex].id;
	// use policy name rather than id as the id!
	asyncXHR('DELETE',origin+'/v1/policies/'+policy+'/rules/'+id,function(xhr) {
		// BUG: Congress creates rules asyncchronously, thus a query for rules immediately after rule creation may not return the newly created rule
		setTimeout('get_rules('+policyIndex+');',1000);
	},null,null,null);	
}

/*
 * Debug feature: delete an arbitrary resource
 */
function delete_resource() {
	resource = document.getElementById('resource').value;
	asyncXHR('DELETE',origin+resource,function(xhr) {
		obj = JSON.parse(xhr.responseText);
		if (obj.error !== undefined) alert(xhr.responseText);
	},null,null,null);
}

function element(type,id,value,indent) {
	e = document.createElement(type);
	e.id = id;
	if (indent !== null) e.style.marginLeft = indent*15+'px';
	if (type == "input") e.placeholder = value;
	else if (value != null) e.innerHTML = value;
	return(e);
}


function br() {
	return (document.createElement('br'));
}

function toggle(obj) {
	var el = document.getElementById(obj);
	if ( el.style.display != 'none' ) {
		el.style.display = 'none';
	}
	else {
		el.style.display = '';
	}
}

function dumpProps(obj, parent, str) {
	if (str == false) str = '';
	try {
	for (var i in obj) {
		if (typeof obj[i] != 'object' && typeof obj[i] != 'function' ) {
			if (parent) { str += parent + '.' + i + ' = ' + obj[i] + '<br/>'; }
			else { str += i + ' = ' + obj[i] + '<br/>'; }
		}
		else {
			if (parent) { str = dumpProps(obj[i], parent + '[' + i + ']', str); }
			else { str = dumpProps(obj[i], i, str); }
		}
	}
	return(str);
	} catch (e) { alert(e); }
}

function asyncXHR(method,url,callback,accept,contentType,body) {
	var xhr = false;
	try { xhr = new XMLHttpRequest(); }
	catch(e1) {}
	if(xhr) {
		try {
			xhr.onreadystatechange = function() {
				if (xhr.readyState === 4) callback(xhr);
			};
			xhr.open(method, url, true);
			if (accept !== null) xhr.setRequestHeader("Accept",accept);
			if (contentType !== null) xhr.setRequestHeader("Content-Type",contentType);
			if (body !== null) xhr.send(body);
			else xhr.send();
		}
		catch(e4) { alert("asyncXHR: xhr send error "+e4.message+" for URL "+url); }
	}
}	

function guidGenerator() {
    var S4 = function() {
       return (((1+Math.random())*0x10000)|0).toString(16).substring(1);
    };
    return (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4());
}
