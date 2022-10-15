<!-- $Id: extractInboundTraces.xslt 11185 2022-02-01 06:58:03Z rafalpa $  -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://saxon.sf.net/" xmlns:ns2="http://com.scc.smx.esbservice/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fun="http://interfaces_function.com" exclude-result-prefixes="#all">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<!--
	****************************************************************************
		*** The main match.
	****************************************************************************
    -->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="not(//fields[id='message']/value/text())">
				<error>Cannot find traces for given message ID. </error>
			</xsl:when>
			<xsl:otherwise>
				<traces>
					<xsl:for-each select="//return[fields[id='message' and value/text()]]">
						<xsl:variable name="source" select="fields[id='source']/value"/>
						<xsl:variable name="destination" select="fields[id='destination']/value"/>
						<xsl:variable name="traceName">
							<xsl:choose>
								<xsl:when test="$source='01_json2xml' and $destination='02_validator'">inboundJsonRequest</xsl:when>
								<xsl:when test="$source='06_canocnical2geneSrv' and $destination='07_submitOrder'">request2Gene</xsl:when>
								<xsl:when test="$source='07_submitOrder' and $destination='08_prepGI'">geneResponse</xsl:when>
								<xsl:when test="$source='11_response2Json' and $destination='12_prepExtResponse'">inboundJsonResponse</xsl:when>
							</xsl:choose>
						</xsl:variable>
						<xsl:element name="trace">
							<xsl:attribute name="name" select="$traceName"/>
							<xsl:attribute name="type">
								<xsl:choose>
									<xsl:when test="$traceName=('request2Gene','geneResponse')">XML</xsl:when>
									<xsl:when test="$traceName=('inboundJsonRequest','inboundJsonResponse')">JSON</xsl:when>
									<xsl:otherwise>UNKNOWN</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
							<xsl:choose>
								<xsl:when test="$traceName=('request2Gene','geneResponse')">
									<xsl:value-of select="fun:getElement(fields[id='message']/value)" disable-output-escaping="yes"/>
								</xsl:when>
								<xsl:when test="$traceName='inboundJsonRequest'">
									<xsl:attribute name="decoding" select="'base64'"/>
									<xsl:variable name="t">
										<xsl:value-of select="fun:getElement(fields[id='message']/value)" disable-output-escaping="yes"/>
									</xsl:variable>
									<xsl:copy-of select="saxon:parse($t)//HttpHeaders"/>
									<xsl:value-of xmlns:base64="java:com.scc.smx.utils.Base64Coder" select="base64:decodeString(string(saxon:parse($t)/Message/Attachments/Attachment/text()),'UTF-8')"/>
									<!--<xsl:value-of select="'altovaTesting'"/>-->
								</xsl:when>
								<xsl:when test="$traceName='inboundJsonResponse'">
									<xsl:variable name="t">
										<xsl:value-of select="fun:getElement(fields[id='message']/value)" disable-output-escaping="yes"/>
									</xsl:variable>
									<xsl:attribute name="status">
										<xsl:value-of select="saxon:parse($t)//Attachments/Attachment[@Name='httpData'][1]"/>
									</xsl:attribute>
									<xsl:copy-of select="concat('{',substring-before(substring-after(fields[id='message']/value,'&gt;{'), '&lt;/Attachment'))"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="'Internal error. No traces found'"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:element>
					</xsl:for-each>
				</traces>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:function name="fun:getElement">
		<xsl:param name="source"/>
		<xsl:variable name="jFront" as="xs:string" select="'&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;'"/>
		<xsl:variable name="jEnd" as="xs:string" select="'properties={'"/>
		<xsl:value-of select="substring-before(substring-after($source,$jFront), $jEnd)" disable-output-escaping="yes"/>
	</xsl:function>
</xsl:stylesheet>