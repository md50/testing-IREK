<!-- $Id: outboundResponse2MOM.xslt 11508 2022-03-16 09:55:05Z rafalpa $  -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions">
	<xsl:output method="html" indent="yes" encoding="UTF-8"/>
	<xsl:variable name="request" select="/traces/trace[@type='REQUEST']"/>
	<xsl:variable name="response" select="/traces/trace[@type='RESPONSE']"/>
	<xsl:template match="/">
		<onMessageResponse xmlns="http://mom.scc.com/" xmlns:ns2="http://com.scc.smx.components.exec">
			<return xmlns="">
				<details>
					<xsl:choose>
						<xsl:when test="matches(//error,'Cannot find traces for given message ID. ')">
							<xsl:text>Cannot find traces for given message ID. Trace was not stored yet or simply removed (too old). Use Diagnostic resend in MOM to recreate trace.</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
							<html>
								<body>
									<style>
                                        .tab {
                                            overflow: hidden;
                                            border: 1px solid #ccc;
                                            background-color: #f1f1f1;
                                        }
                                        
                                        /* Style the buttons inside the tab */
                                        .tab button {
                                            background-color: inherit;
                                            float: left;
                                            border: none;
                                            outline: none;
                                            cursor: pointer;
                                            padding: 14px 16px;
                                            transition: 0.3s;
                                            font-size: 17px;
                                        }
                                        
                                        
                                        .tab button:hover {
                                            background-color: #ddd;
                                        }
                                        
                                        /* Create an active/current tablink class */
                                        .tab button.active {
                                            background-color: #ccc;
                                        }
                                        
                                        
                                        .tabcontent {
                                            display: none;
                                            padding: 6px 12px;
                                            border: 1px solid #ccc;
                                            border-top: none;
                                        }
										pre {
											outline: 1px solid #ccc;
											padding: 5px;
											margin: 5px;
											font-family: 'Courier New', Courier, monospace;
											overflow-x: auto;
											white-space: pre-wrap;
										}
								
										.string {
											color: green;
										}
								
										.number {
											color: darkorange;
										}
								
										.boolean {
											color: blue;
										}
								
										.null {
											color: magenta;
										}
								
										.key {
											color: red;
										}
										h1, h3{
											font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
											margin-left: 5px;
										}
										h2 {
											font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
											margin-left: 10px;
										}
										h4 {
											font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
											margin-left: 20px;
											color: rgb(105,105,105);
										}
									</style>
									<h1>LabTek request and response traces</h1>
									<div class="tab">
                                        <button class="tablinks" onclick="openTab(event, 'Request')" id="defaultOpen">Request</button>
                                        <button class="tablinks" onclick="openTab(event, 'Response')">Response</button>
                                        
                                    </div>
									<div id="Request" class="tabcontent">
                                        <h4>
											<xsl:for-each select="$request/*[not(local-name()=('content','status'))]">
												<br>
													<i><xsl:value-of select="concat(local-name(),'=',.)"/></i>
												</br>	
											</xsl:for-each>
										</h4>
										<content>
											<pre id="json_request" style="background-color: rgb(241, 241, 241);"/>
										</content>
									</div>
                                    <div id="Response" class="tabcontent">
                                        <h4>
											<xsl:for-each select="$response/*[not(local-name()=('content','contentType'))]">
												<br>
													<i><xsl:value-of select="concat(local-name(),'=',.)"/></i>
												</br>	
											</xsl:for-each>
										</h4>
										<content>
											<pre id="json_response" style="background-color: rgb(241, 241, 241);"/>
										</content>
                                    </div>
								</body>
								<script type="application/javascript">
									var request = <xsl:value-of select="if ((starts-with($request/content, '{') and ends-with($request/content, '}')) or (starts-with($request/content, '[') and ends-with($request/content, ']'))) then concat(normalize-space($request/content),';') else concat('`',replace(normalize-space($response/content),'`','\\`'),'`')"/>
                                    var response =  <xsl:value-of select="if ((starts-with($response/content, '{') and ends-with($response/content, '}')) or (starts-with($response/content, '[') and ends-with($response/content, ']'))) then concat(normalize-space($response/content),';') else concat('`',replace(normalize-space($response/content),'`','\\`'),'`')"/>
                                    
									function isValidJSONString(str) {
									try {
											JSON.parse(str);
										} catch (e) {
											return false;
										}
										return true;
									};
									
									
									function syntaxHighlight(json) {
										json = json.replace(/&amp;/g, '&amp;').replace(/&lt;/g, '&lt;').replace(/>/g, '&gt;');
										return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
											var cls = 'number';
											if (/^"/.test(match)) {
												if (/:$/.test(match)) {
													cls = "key";
												} else {
													cls = "string";
												}
											} else if (/true|false/.test(match)) {
												cls = "boolean";
											} else if (/null/.test(match)) {
												cls = "null";
											}
											return &apos;&lt;span class=&quot;&apos; + cls + &apos;&quot;&gt;&apos; + match + &apos;&lt;/span&gt;&apos;;
										});
									};
															
									// Response and Request Formatting:
									
									if (typeof(request) == 'object') {
										var request_str = JSON.stringify(request, undefined, 2);
										document.getElementById("json_request").innerHTML = syntaxHighlight(request_str);
										
									}
									else {
										document.getElementById("json_request").innerHTML = request;
									}
									
									if (typeof(response) == 'object') {
										var response_str = JSON.stringify(response, undefined, 2);
										document.getElementById("json_response").innerHTML = syntaxHighlight(response_str);
										
									}
									else {
										document.getElementById("json_response").innerHTML = response;
									}
									
									// Tab handling

                                    function openTab(evt, tabName) {
                                        var i, tabcontent, tablinks;
                                        tabcontent = document.getElementsByClassName("tabcontent");
                                        for (i = 0; i &lt; tabcontent.length; i++) {
                                          tabcontent[i].style.display = "none";
                                        }
                                        tablinks = document.getElementsByClassName("tablinks");
                                        for (i = 0; i &lt; tablinks.length; i++) {
                                          tablinks[i].className = tablinks[i].className.replace(" active", "");
                                        }
                                        document.getElementById(tabName).style.display = "block";
                                        evt.currentTarget.className += " active";
                                      }
                                      
                                      // Get the element with id="defaultOpen" and click on it
                                      document.getElementById("defaultOpen").click();
								</script>
							</html>
							<xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</details>
				<resultCode>
					<xsl:choose>
						<xsl:when test="error">1</xsl:when>
						<xsl:otherwise>0</xsl:otherwise>
					</xsl:choose>
				</resultCode>
				<destMsgId/>
			</return>
		</onMessageResponse>
	</xsl:template>
</xsl:stylesheet>
