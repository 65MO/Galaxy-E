
<%namespace file="ie.mako" name="ie"/>
<%
import os
import shutil
import time

# Sets ID and sets up a lot of other variables
ie_request.load_deploy_config()
ie_request.attr.docker_port = 80
image=trans.request.params.get('image_tag', None)
# Did the user give us an RData file?
CNVdata = ie_request.volume(hda.file_name, '/srv/shiny-server/data/inputdata.txt', how='ro')
ie_request.launch(
	volumes=[CNVdata],
	image=trans.request.params.get('image_tag', None),
	env_override={
    		'PUB_HOSTNAME': ie_request.attr.HOST,
})

## General IE specific
#if image=="shiny-gie-gis-region:latest":
#   notebook_access_url = ie_request.url_template('${PROXY_URL}/sample-apps/SIG/?')
#else:
#   notebook_access_url = ie_request.url_template('${PROXY_URL}?')	
#endif
notebook_access_url = ie_request.url_template('${PROXY_URL}/sample-apps/STAT/inst/app/?')

root = h.url_for( '/' )

%>
<html>
<head>
${ ie.load_default_js() }
</head>
<body style="margin:0px">
<script type="text/javascript">

        ${ ie.default_javascript_variables() }
        var notebook_access_url = '${ notebook_access_url }';
        ${ ie.plugin_require_config() }

        requirejs(['interactive_environments', 'plugin/bam_iobio'], function(){
            display_spinner();
        });

        toastr.info(
            "Loading data into the App",
            "...",
            {'closeButton': true, 'timeOut': 5000, 'tapToDismiss': false}
        );
        var startup = function(){
            // Load notebook
          requirejs(['interactive_environments', 'plugin/bam_iobio'], function(){
             //  requirejs(['interactive_environments'], function(){
                load_notebook(notebook_access_url);
            });

        };
        // sleep 5 seconds
        // this is currently needed to get the vis right
        // plans exists to move this spinner into the container
        setTimeout(startup, 5000);

</script>
<div id="main">
</div>
</body>
</html>
