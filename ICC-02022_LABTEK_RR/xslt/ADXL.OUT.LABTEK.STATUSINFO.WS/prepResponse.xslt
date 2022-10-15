<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: prepResponse.xslt 11722 2022-04-26 12:56:50Z jzajdel $  -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ns0="http://mom.scc.com/" xmlns:mom="http://mom.scc.com/" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" 
xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns5="http://www.softcomputer.com/RequisitionOrderingService/" xmlns:ns2="http://www.softcomputer.com/GeneOrderingService/"
xmlns:ns4="http://www.softcomputer.com/SoftGeneOrderingService/" exclude-result-prefixes="#all">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:variable name="data" select="/join//Message//Data"/>
	<xsl:variable name="httpRespondCode" select="if (string($data/Parameters/@httpRespondCode)) then $data/Parameters/@httpRespondCode else /join/SOAP-ENV:Fault/detail/HTTP_ERROR/HttpData/Parameters/@httpRespondCode"/>
	<xsl:variable name="responseDetails" select="if ($data/root/status/details/text()) then $data/root/status/details else /join/SOAP-ENV:Fault/detail/HTTP_ERROR/HttpData/respond"/>
	<xsl:variable name="error" select="if (/join/SOAP-ENV:Fault/detail/Message/Data/root/error/text()) then /join/SOAP-ENV:Fault/detail/Message/Data/root/error else /join/SOAP-ENV:Fault/detail/HTTP_ERROR/HttpData/error"/>
	<xsl:variable name="newLine" select="'&#xA;'"/>
	<xsl:variable name="transactionId" select="/join//Data/root/transactionId"/>
	<xsl:variable name="muti" select="/join/*:onMessage/msg/muti"/>
	<xsl:variable name="retry" select="number(substring-after(substring-after($muti,concat($transactionId,':')),':'))"/>
	<!-- copy copy -->
	<xsl:template match="@* | node()">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:variable name="status">
		<xsl:element name="code">
			<xsl:choose>
				<xsl:when test="join/retry">
					<xsl:attribute name="text" select="join/retry/text()"/>
					<xsl:text>2</xsl:text>
				</xsl:when>
				<xsl:when test="join/Message/Header/Route = 'MISSING_TEST'">
					<xsl:attribute name="text">Missing or empty [TEST] attribute</xsl:attribute>
					<xsl:text>9</xsl:text>
				</xsl:when>
				<xsl:when test="join/Message/Header/Route = 'MISSING_GI'">
					<xsl:attribute name="text">Missing GI entry for test [<xsl:value-of select="join/Message/Event/msg/attributes[name = 'TEST']/value"/>].</xsl:attribute>
					<xsl:text>2</xsl:text>
				</xsl:when>
				<xsl:when test="join/mom:onMessage/msg/attributes[name='REPORTABLE_TEST']/contains(value,',')">
					<xsl:attribute name="text">Multiple tests provided. Splitting event for each reportable test.</xsl:attribute>
					<xsl:attribute name="split">true</xsl:attribute>
					<xsl:text>0</xsl:text>
				</xsl:when>
				<xsl:when test="join/skip">
					<xsl:attribute name="text" select="join/skip/@details"/>
					<xsl:value-of select="join/skip/@status"/>
				</xsl:when>
				<xsl:when test="join/error">
					<xsl:attribute name="text" select="join/error"/>
					<xsl:text>1</xsl:text>
				</xsl:when>
				<xsl:when test="/join/Message/Header/Status='ok' and starts-with($httpRespondCode,'2')">
					<xsl:attribute name="text" select="concat('LabTek returned status: OK', if (string($responseDetails)) then concat(' with details: ',$responseDetails) else '')"/>
					<xsl:text>0</xsl:text>
				</xsl:when>
				<!--<xsl:when test="$httpRespondCode='423'">
					<xsl:attribute name="text" select="if (string($responseDetails)) then concat('LabTek returned: ',$responseDetails) else 'LabTek returned: the resource that is being accessed is locked.'"/>
					<xsl:value-of select="'2'"/>
				</xsl:when>-->
				<xsl:when test="join/SOAP-ENV:Fault">
					<xsl:attribute name="text" select="concat('Server returned error:',$newLine,
					'- httpRespondCode = ',$httpRespondCode,$newLine,
					if ($error/name/text()) then concat('- name = ',$error/name,$newLine) else '',
					if ($error/header/text()) then concat('- header = ',$error/header,$newLine) else '',
					if ($responseDetails/text()) then concat('- response = ',$responseDetails,$newLine) else '',
					if ($error/text()) then concat('- error = ',$error) else ''
					)"/>
					<xsl:choose>
						<xsl:when test="$httpRespondCode=('110','429')">2</xsl:when>
						<xsl:when test="$httpRespondCode='423'">10</xsl:when>
						<xsl:when test="starts-with($httpRespondCode, '5')">2</xsl:when>
						<xsl:otherwise>1</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="text" select="concat('LabTek returned:',$newLine,
					'- httpRespondCode = ',$httpRespondCode,$newLine,
					'- message = ',$responseDetails)"/>
					<xsl:text>1</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
	</xsl:variable>
	<!-- -->
	<!-- =================================== create mess ================================  -->
	<xsl:template match="/">
		<xsl:element name="mom:onMessageResponse">
			<return>
				<xsl:if test="not($status/code = ('0','2','9'))">
					<xsl:call-template name="createProblem">
						<xsl:with-param name="processingCode"><xsl:value-of select="$httpRespondCode"/></xsl:with-param>
						<xsl:with-param name="processingText"><xsl:value-of select="$status/code/@text"/></xsl:with-param>
					</xsl:call-template>
				</xsl:if>
				<xsl:message select="$status"/>
				<resultCode><xsl:value-of select="$status/code"/></resultCode>
				<details><xsl:value-of select="$status/code/@text"/></details>
				<destMsgId><xsl:value-of select="join/ns0:onMessage/msg/destMsgId"/></destMsgId>
				<xsl:if test="not($status/code='9')">
					<xsl:element name="processingCode"><xsl:value-of select="concat('HTTP_',$httpRespondCode)"/></xsl:element>
				</xsl:if>
				<xsl:if test="$status/code/@split">
					<xsl:variable name="onMessage" select="join/mom:onMessage"/>
					<xsl:for-each select="tokenize(join/mom:onMessage/msg/attributes[name='REPORTABLE_TEST']/value,',')">
						<xsl:message select="."/>
						<messages>
							<xsl:copy-of select="$onMessage/msg/(attributes[not(name = ('TEST','REPORTABLE_TEST'))] | senderCode | eventCode | msgText)" copy-namespaces="no"/>
							<attributes>
								<name>TEST</name>
								<value><xsl:value-of select="normalize-space(.)"/></value>
							</attributes>
							<destinations>WS.ADXL.OUT.LABTEK.STATUSINFO</destinations>
						</messages>
					</xsl:for-each>
				</xsl:if>
			</return>
		</xsl:element>
	</xsl:template>
	<xsl:template name="createProblem">
		<xsl:param name="processingCode"/>
		<xsl:param name="processingText"/>
		<xsl:element name="problems" namespace="">
			<xsl:if test="$processingCode"><xsl:element name="processingCode" namespace=""><xsl:value-of select="concat('HTTP_',$processingCode)"/></xsl:element></xsl:if>
			<xsl:if test="$processingText"><xsl:element name="processingText" namespace=""><xsl:value-of select="$processingText"/></xsl:element></xsl:if>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>
