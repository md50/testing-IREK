<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: cmnPrepResponse.xslt 12142 2022-07-14 16:57:16Z rafalpa $  -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ns0="http://mom.scc.com/" xmlns:mom="http://mom.scc.com/" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" 
xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns5="http://www.softcomputer.com/RequisitionOrderingService/" xmlns:ns2="http://www.softcomputer.com/GeneOrderingService/"
xmlns:ns4="http://www.softcomputer.com/SoftGeneOrderingService/">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:variable name="messId" select="/join/*:onMessage/msg/destMsgId"/>
	<xsl:variable name="data" select="/join//Message//Data"/>
	<xsl:variable name="httpRespondCode" select="if (string($data/Parameters/@httpRespondCode)) then $data/Parameters/@httpRespondCode else /join/SOAP-ENV:Fault/detail/HTTP_ERROR/HttpData/Parameters/@httpRespondCode"/>
	<xsl:variable name="responseDetails" select="if ($data/root/status/details/text()) then $data/root/status/details else /join/SOAP-ENV:Fault/detail/HTTP_ERROR/HttpData/respond"/>
	<xsl:variable name="newLine" select="'&#xA;'"/>
	<xsl:variable name="event" select="/join/*:onMessage/msg/attributes[name='EVENT']/value"/>
	<xsl:variable name="error" select="if (/join/SOAP-ENV:Fault/detail/Message/Data/root/error/text()) then /join/SOAP-ENV:Fault/detail/Message/Data/root/error else /join/SOAP-ENV:Fault/detail/HTTP_ERROR/HttpData/error"/>
	<xsl:variable name="diagnosticDelivery" select="/join/*:onMessage/msg/diagnosticDelivery"/>
	<xsl:variable name="source" select="/join/Message/Header/Source"/>
	<xsl:variable name="message">
		<xsl:choose>
			<xsl:when test="starts-with($httpRespondCode,'1') and not($httpRespondCode='110')"><xsl:text>The request was received, continuing process.</xsl:text></xsl:when>
			<xsl:when test="$httpRespondCode='110'"><xsl:text>Connection Timed Out</xsl:text></xsl:when>
			<xsl:when test="starts-with($httpRespondCode,'3')"><xsl:text>Further action needs to be taken in order to complete the request.</xsl:text></xsl:when>
			<xsl:when test="$httpRespondCode='400'"><xsl:text>Bad Request. The request could not be understood by the server due to incorrect syntax.</xsl:text></xsl:when>
			<xsl:when test="$httpRespondCode='401'"><xsl:text>Unauthorized. The request requires user authentication information.</xsl:text></xsl:when>
			<xsl:when test="$httpRespondCode='403'"><xsl:text>Forbidden. Unauthorized request. The client does not have access rights to the content.</xsl:text></xsl:when>
			<xsl:when test="$httpRespondCode='404'"><xsl:text>Not Found. The server can not find the requested resource.</xsl:text></xsl:when>
			<xsl:when test="$httpRespondCode='408'"><xsl:text>Request Timeout. The server did not receive a complete request from the client within the servers allotted timeout period.</xsl:text></xsl:when>
			<xsl:when test="$httpRespondCode='423'"><xsl:text>Locked. The resource that is being accessed is locked.</xsl:text></xsl:when>
			<xsl:when test="$httpRespondCode='429'"><xsl:text>The user has sent too many requests in a given amount of time.</xsl:text></xsl:when>
			<xsl:when test="$httpRespondCode='500'"><xsl:text>Internal Server Error.</xsl:text></xsl:when>
			<xsl:when test="$httpRespondCode='501'"><xsl:text>Not Implemented. The server did not recognize the request method or is unable to fulfill the request.</xsl:text></xsl:when>
			<xsl:when test="$httpRespondCode='503'"><xsl:text>Service Unavailable. The server cannot handle the request.</xsl:text></xsl:when>
			<xsl:when test="starts-with($httpRespondCode,'5')"><xsl:text>The server failed to fulfil an apparently valid request.</xsl:text></xsl:when>
			<xsl:otherwise><xsl:text>UNKNOWN ERROR</xsl:text></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:param name="externalURL">${externalURL}</xsl:param>
	<!--<xsl:param name="externalURL">CLIENT_URL</xsl:param>-->
	<!-- copy copy -->
	<xsl:template match="@* | node()">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:variable name="status">
		<xsl:element name="code">
			<xsl:choose>
				<xsl:when test="$diagnosticDelivery='true' and $source='JSON'">
					<xsl:attribute name="text" select="'Diagnostic resend (LabTek was not called). JSON results message is available in ESB traces.'"/>
					<xsl:value-of select="'9'"/>
				</xsl:when>
				<xsl:when test="join/skip">
					<xsl:attribute name="source" select="join/skip/@source"/>
					<xsl:attribute name="text" select="join/skip/@details"/>
					<xsl:value-of select="join/skip/@status"/>
				</xsl:when>
				<xsl:when test="join/error">
					<xsl:if test="$externalURL=('CLIENT_URL','') or contains(join/error,'DICT.HOST_WS')">
						<xsl:attribute name="source" select="'checkSettings'"/>
					</xsl:if>
					<xsl:attribute name="text" select="if ($externalURL=('CLIENT_URL','')) then concat('Please check externalURL interface parameter.',$newLine, 'Response: ', join/error) else concat('Please check global SoftDMI parameter HOST_WS settings, it should be proper outbound URL endpoint set : ',join/error)"/>
					<xsl:value-of select="'1'"/>
				</xsl:when>
				<xsl:when test="/join/Message/Header/Resource='newTest' and 
								not(//msg/attributes[name='AUXILIARY_ORDER']/value/text()) and 
								(/join/ns2:SubmitOrderResponse/ns2:Result='false' or not(/join/ns2:SubmitOrderResponse/ns2:SubmitOrderResult/ns4:RequestStatus/ns4:StatusNumber='0'))">
					<xsl:attribute name="text" select="'Error response from Gene. Auxiliary order number was not updated.'"/>
					<xsl:value-of select="'1'"/>
				</xsl:when>
				<xsl:when test="/join/Message/Header/Status='ok' and starts-with($httpRespondCode,'2')">
					<xsl:attribute name="text" select="concat('LabTek returned status: OK', if (string($responseDetails)) then concat(' with details: ',$responseDetails) else '', 
														if (/join/Message/Header/Resource='newTest' and /join/ns2:SubmitOrderResponse/ns2:SubmitOrderResult/ns4:RequestStatus/ns4:StatusNumber='0') then 
															concat($newLine,'GENE was updated with auxiliary order number:',$newLine ,'- GENE order number: ', /join/ns2:SubmitOrderResponse/ns2:SubmitOrderResult/ns4:UpdatedOrders/ns4:OrderNumber,$newLine,
															                                                '- AUX order number: ', /join/ns2:SubmitOrderResponse/ns2:SubmitOrderResult/ns4:UpdatedOrders/ns4:AuxiliaryOrder) else 
															    if (/join/Message/Header/Resource='results' and /join/Message/StoredProcParams/returnFromProcedure/errCode='0') then
															        concat($newLine, 'GI entry has been updated.') else '')"/>
					<xsl:value-of select="'0'"/>
				</xsl:when>
				<xsl:when test="join/SOAP-ENV:Fault">
					<xsl:attribute name="text" select="concat('Server returned error:',$newLine,
					'- httpRespondCode = ',$httpRespondCode,$newLine,
					if ($error/name/text()) then concat('- name = ',$error/name,$newLine) else '',
					if ($error/message/text()) then concat('- message = ', $error/message,$newLine) else concat('- message = ',$message),
					if ($error/header/text()) then concat($newLine,'- header = ',$error/header) else '',
					if ($responseDetails/text()) then concat($newLine,'- response = ',$responseDetails) else '',
					if ($error/text()) then concat($newLine,'- error = ',$error) else ''
					)"/>
					<xsl:choose>
						<xsl:when test="$httpRespondCode=('110','429')">2</xsl:when>
						<xsl:when test="$httpRespondCode='423'">10</xsl:when>
						<xsl:when test="starts-with($httpRespondCode, '5')">2</xsl:when>
						<xsl:when test="$event=('TEST_RESEND','ORDER_RESEND') and $httpRespondCode='400'">9</xsl:when>
						<xsl:otherwise>1</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="text" select="concat('LabTek returned:',$newLine,
					'- httpRespondCode = ',$httpRespondCode,$newLine,
					'- message = ',$responseDetails)"/>
					<xsl:value-of select="'1'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
	</xsl:variable>
	<!-- -->
	<!-- =================================== create mess ================================  -->
	<xsl:template match="/">
		<!--<xsl:message>
			<xsl:copy-of select="$status"/>
		</xsl:message>-->
		<xsl:call-template name="CreateMomResponse">
			<xsl:with-param name="MomText" select="$status/code/@text"/>
			<xsl:with-param name="MomCode" select="$status/code"/>
			<xsl:with-param name="Source" select="$status/code/@source"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template name="CreateMomResponse" exclude-result-prefixes="#all">
		<xsl:param name="MomText"/>
		<xsl:param name="MomCode"/>
		<xsl:param name="Source"/>
		<xsl:param name="CreateProblem"/>
		<xsl:param name="DirectResponse"/>
		<xsl:element name="mom:onMessageResponse">
			<return>
				<xsl:if test="not($MomCode=('0','2','9'))">
					<xsl:call-template name="createProblem">
						<xsl:with-param name="processingCode">
							<!--<xsl:choose>
								<xsl:when test="$Source='GI'">GI_ERROR</xsl:when>
								<xsl:when test="$Source='checkSettings'">CONFIG_ERROR</xsl:when>
								<xsl:otherwise>INCORRECT_TRANSACTION</xsl:otherwise>
							</xsl:choose>-->
							<xsl:value-of select="$httpRespondCode"/>
						</xsl:with-param>
						<xsl:with-param name="processingText">
							<xsl:value-of select="$MomText"/>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:if>
				<resultCode>
					<xsl:value-of select="$MomCode"/>
				</resultCode>
				<xsl:element name="details">
					<xsl:value-of select="$MomText"/>
				</xsl:element>
				<xsl:element name="destMsgId">
					<xsl:value-of select="$messId"/>
				</xsl:element>
				<xsl:choose>
					<xsl:when test="$event=('TEST_RESEND','ORDER_RESEND') and $httpRespondCode='400'">
						<xsl:element name="processingCode">
							<xsl:value-of select="concat('HTTP_',$httpRespondCode)"/>
						</xsl:element>
					</xsl:when>
					<xsl:when test="not($MomCode='9')">
						<xsl:element name="processingCode">
							<xsl:value-of select="concat('HTTP_',$httpRespondCode)"/>
						</xsl:element>
					</xsl:when>
				</xsl:choose>
			</return>
		</xsl:element>
	</xsl:template>
	<xsl:template name="createProblem">
		<xsl:param name="processingCode"/>
		<xsl:param name="processingText"/>
		<xsl:element name="problems" namespace="">
			<xsl:if test="$processingCode">
				<xsl:element name="processingCode" namespace="">
					<xsl:value-of select="concat('HTTP_',$processingCode)"/>
				</xsl:element>
			</xsl:if>
			<xsl:if test="$processingText">
				<xsl:element name="processingText" namespace="">
					<xsl:value-of select="$processingText"/>
				</xsl:element>
			</xsl:if>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>
