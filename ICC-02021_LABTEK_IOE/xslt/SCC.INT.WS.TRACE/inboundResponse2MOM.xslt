<!-- $Id: inboundResponse2MOM.xslt 11185 2022-02-01 06:58:03Z rafalpa $  -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions">
	<xsl:output method="html" indent="yes" encoding="UTF-8"/>
	<xsl:variable name="apos">&apos;</xsl:variable>
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
										textarea {
											width: 100%;
											height: 100%;
											overflow: hidden;
											padding: 10px;
											wrap: off;
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
									<h1>Inbound interface request and response traces</h1>
									<div class="tab">
										<xsl:for-each select="//trace">
											<xsl:sort select="@type"/>
											<xsl:variable name="name" select="@name"/>
											<!--<button class="tablinks" onclick="openTab(event, 'Request')" id="defaultOpen">Request</button>-->
											<xsl:element name="button">
												<xsl:attribute name="class" select="'tablinks'"/>
												<xsl:attribute name="onclick" select="concat('openTab(event, ',$apos,$name,$apos,')')"/>
												<xsl:if test="position()=1">
													<xsl:attribute name="id" select="'defaultOpen'"></xsl:attribute>
												</xsl:if>
												<xsl:value-of select="$name"/>
											</xsl:element>
										</xsl:for-each>
									</div>
									<xsl:for-each select="//trace">
										<xsl:variable name="name" select="@name"/>
										<div id="{$name}" class="tabcontent">
											<xsl:if test="$name='inboundJsonRequest'">
												<h4>
													<xsl:for-each select="HttpHeaders/header[not(@name=('Authorization'))]">
														<br>
															<i><xsl:value-of select="concat(@name,' = ',@value)"/></i>
														</br>	
													</xsl:for-each>
												</h4>
											</xsl:if>
											<xsl:if test="$name='inboundJsonResponse'">
												<h4>
													<br>
														<i><xsl:value-of select="'METHOD = POST'"/></i>
													</br>
													<xsl:if test="@status">
														<br>
															<i><xsl:value-of select="concat('status = ',@status)"/></i>
														</br>
													</xsl:if>	
												</h4>
											</xsl:if>
											<content>
												<xsl:choose>
													<xsl:when test="@type='JSON'">
														<pre style="background-color: rgb(241, 241, 241);">
															<xsl:attribute name="id" select="concat('content_',$name)"/>
														</pre>
													</xsl:when>
													<xsl:when test="@type='XML'">
														<textarea> 
															<xsl:copy-of select="*"/>
														</textarea>
													</xsl:when>
												</xsl:choose>
											</content>
										</div>
									</xsl:for-each>
                                </body>
                                <script type="application/javascript">
									<xsl:for-each select="//trace">
										<xsl:variable name="name" select="@name"/>
										<xsl:if test="@type='JSON'">
											var <xsl:value-of select="$name"/> = '<xsl:value-of select="normalize-space(.)"/>';
										</xsl:if>
										
										// Response and Request Formatting:
										<xsl:if test="@type='JSON'">
										
										if (isValidJSONString(<xsl:value-of select="$name"/>)) {
											var <xsl:value-of select="$name"/>_str = JSON.stringify(JSON.parse(<xsl:value-of select="$name"/>), undefined, 2);
											document.getElementById("content_<xsl:value-of select="$name"/>").innerHTML = syntaxHighlight(<xsl:value-of select="$name"/>_str);
											
										}
										else {
											document.getElementById("content_<xsl:value-of select="$name"/>").innerHTML = <xsl:value-of select="$name"/>;
										}
										
										</xsl:if>
									
									</xsl:for-each>
									
									
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