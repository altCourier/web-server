/**
 * @file parser.c
 */

/**
 * @brief Parses the request path
 * @param request Raw HTTP request string
 * @param method Output buffer for HTTP method
 * @param path Output buffer for requested path
 * @param version Output buffer for HTTP version
 * @return 0 on success, -1 on failure
 */
int parse_request_line(const char* request, char* method, char* path, char* version) {
	
	if (!request || !method || !path || !version) {
		return -1;
	}
	
	const char* line_end = strstr(request, "\r\n");
	
	if (!line_end) {
		
		line_end = strchr(request, '\n');
		
		if (!line_end) {
			return -1;
		}
	}
	
	char first_line[512];
	int line_len = line_end - request;
	
	strncpy(first_line, request, line_len);
	first_line[line_len] = '\0';
	
	return (sscanf(first_line, "%s %s %s", method, path, version) == 3) ? 0 : -1;
}