<!-- $Id: extractOutboundTraces.xslt 11155 2022-01-25 20:19:19Z rafalpa $  -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://saxon.sf.net/" xmlns:ns2="http://com.scc.smx.esbservice/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fun="http://interfaces_function.com" exclude-result-prefixes="#all">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>
	<xsl:strip-space elements="*"/>
	<!-- ****************************************************************************        
		*** 	The main match. 
		***************************************************************************** -->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="not(//fields[id='message']/value/text())">
				<error>Cannot find traces for given message ID. </error>
			</xsl:when>
			<xsl:otherwise>
				<traces>
					<xsl:for-each select="//fields[id='message']/value">
						<!--e.g.:						
						&lt;encoding&gt;UTF-8&lt;/encoding&gt;
						&lt;type&gt;RESPONSE&lt;/type&gt;-->
						<xsl:element name="trace">
							<xsl:attribute name="type" select="fun:getElement(.,'type')"/>
							<xsl:call-template name="createHeader">
								<xsl:with-param name="source" select="."/>
							</xsl:call-template>
							<xsl:copy-of select="fun:getElement(.,'content')"/>
						</xsl:element>
					</xsl:for-each>
				</traces>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="createHeader">
		<xsl:param name="source"/>
		<xsl:element name="method">
			<xsl:value-of select="fun:getElement($source,'method')"/>
		</xsl:element>
		<xsl:element name="encoding">
			<xsl:value-of select="fun:getElement($source,'encoding')"/>
		</xsl:element>
		<xsl:element name="status">
			<xsl:value-of select="fun:getElement($source,'status')"/>
		</xsl:element>
		<xsl:element name="url">
			<xsl:value-of select="fun:getElement($source,'url')"/>
		</xsl:element>
		<xsl:element name="contentType">
			<xsl:value-of select="fun:getElement($source,'contentType')"/>
		</xsl:element>
		<xsl:element name="contentLength">
			<xsl:value-of select="fun:getElement($source,'contentLength')"/>
		</xsl:element>
	</xsl:template>
	<xsl:function name="fun:getElement">
		<xsl:param name="source"/>
		<xsl:param name="elementName"/>
		<xsl:variable name="jFront" as="xs:string" select="concat('&lt;',$elementName,'&gt;')"/>
		<xsl:variable name="jEnd" as="xs:string" select="concat('&lt;/',$elementName,'&gt;')"/>
		<xsl:copy-of select="saxon:parse(concat($jFront, substring-after(substring-before($source, $jEnd), $jFront), $jEnd))"/>
	</xsl:function>
</xsl:stylesheet>
