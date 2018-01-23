<%namespace name="ie" file="ie.mako" />
<%
# Sets ID and sets up a lot of other variables
ie_request.load_deploy_config()



# Get ids of selected datasets
additional_ids = trans.request.params.get('additional_dataset_ids', None)
if not additional_ids:
    additional_ids = str(trans.security.encode_id( hda.id ) )
else:
    additional_ids += "," + trans.security.encode_id( hda.id )


# Launch the IE. This builds and runs the docker command in the background.
ie_request.launch(
additional_ids=additional_ids if ie_request.use_volumes else None,
    env_override={
        'DATASET_HID': hda.hid,
        'DATASET_NAME': hda.name
    }
)



# Only once the container is launched can we template our URLs. The ie_request
# doesn't have all of the information needed until the container is running.
url = ie_request.url_template('${PROXY_URL}/openrefine/')
%>
<html>
<head>
${ ie.load_default_js() }
</head>
<body>
<script type="text/javascript">
${ ie.default_javascript_variables() }
var url = '${ url }';
${ ie.plugin_require_config() }
requirejs(['interactive_environments', 'plugin/openrefine'], function(){
    load_notebook(url);
});
</script>
<div id="main" width="100%" height="100%">
</div>
</body>
</html>
