// ==UserScript==
// @name        Scrobble Cleanup
// @namespace   mstamat
// @author      mstamat
// @description last.fm helper to remove unwanted scrobbles (e.g. from ads).
// @include     http://www.last.fm/user/*/library/music/*/_/*
// @version     1
// @require     http://code.jquery.com/jquery-2.2.4.min.js
// @grant       GM_getValue
// @grant       GM_setValue
// @grant       GM_deleteValue
// ==/UserScript==

// ******** Bootstrap Spinner: http://codepen.io/Thomas-Lebeau/pen/csHqx *****************************
var spinner_css = [
'<style type="text/css">',
'.spinner {',
'}',
'.spinner input {',
    'text-align: right;',
'}',
'.input-group-btn-vertical {',
    'position: relative;',
    'white-space: nowrap;',
    'width: 1%;',
    'vertical-align: middle;',
    'display: table-cell;',
'}',
'.input-group-btn-vertical > .btn {',
    'display: block;',
    'float: none;',
    'width: 100%;',
    'max-width: 100%;',
    'padding: 8px;',
    'margin-left: -1px;',
    'position: relative;',
    'border-radius: 0;',
'}',
'.input-group-btn-vertical > .btn:first-child {',
    'border-top-right-radius: 4px;',
'}',
'.input-group-btn-vertical > .btn:last-child {',
    'margin-top: -2px;',
    'border-bottom-right-radius: 4px;',
'}',
'.input-group-btn-vertical i{',
    'position: absolute;',
    'top: 0;',
    'left: 4px;',
'}',
'</style>'
].join("\r\n");
var spinner_html = [
'<div class="col-md-4"><div class="input-group spinner">',
    '<input type="text" class="form-control" value="5">',
    '<div class="input-group-btn-vertical">',
        '<button class="btn btn-default" type="button"><i class="fa fa-caret-up"></i></button>',
        '<button class="btn btn-default" type="button"><i class="fa fa-caret-down"></i></button>',
    '</div>',
'</div></div>'
].join("\r\n");


// alias jquery
var $jq = jQuery.noConflict(true);

// append css
$jq("head").append('<link href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" rel="stylesheet" type="text/css">');
$jq("head").append('<link href="//maxcdn.bootstrapcdn.com/font-awesome/4.6.3/css/font-awesome.min.css" rel="stylesheet" type="text/css">');
$jq("head").append(spinner_css);

// get the metadata display object
var metadata = $jq('ul.metadata-list');


// ******** Remove spinner and button ****************************************************************
// append another item to metadata list
var scrobble_mass_remove = metadata.children('li.metadata-item').first().clone();
scrobble_mass_remove.children('.metadata-title').text('Scrobble Remover');
scrobble_mass_remove.children('.metadata-display').html('<div class="row scrobble-mass-remove"></div>');
metadata.append(scrobble_mass_remove);

// add ui elements to new item
var spinner = $jq(spinner_html);
var button = $jq('<div class="col-md-4"><button type="button" value="Remove" class="btn btn-sm btn-danger scrobble-mass-remove-button">Remove</button></div>');
$jq('.scrobble-mass-remove').append(spinner);
$jq('.scrobble-mass-remove').append(button);

// spinner controller actions
$jq('.spinner .btn:first-of-type').on('click', function() {
    $jq('.spinner input').val(parseInt($jq('.spinner input').val(), 10) + 1);
});
$jq('.spinner .btn:last-of-type').on('click', function() {
    $jq('.spinner input').val(parseInt($jq('.spinner input').val(), 10) - 1);
});

// remove button action
$jq('.scrobble-mass-remove button.scrobble-mass-remove-button').click(function(){doRemove();});


// ******** Progress Indicator ***********************************************************************
// append another item to metadata list
var scrobble_mass_remove_progress = metadata.children('li.metadata-item').first().clone();
scrobble_mass_remove_progress.children('.metadata-title').text('');
scrobble_mass_remove_progress.children('.metadata-display').html('');
metadata.append(scrobble_mass_remove_progress);


// ******** Helpers***********************************************************************************
function nscrobbles_update() {
  // updates the number of scrobbles to have some indication of progress
  var nscrobbles = $jq(".library-track-metadata .metadata-display").first();
  nscrobbles.text( parseInt(nscrobbles.text().replace(/,/, '')) - 1 );
}

function doRemove(resume_data) {
    var remove_total = 0;
    var removed = 0;

    // initialize counters
    if (resume_data) {
        remove_total = resume_data.remove_total;
        removed = resume_data.removed;
    }
    else {
        remove_total = $jq('.scrobble-mass-remove .spinner input').val();
        removed = 0;
    }

    // alert(removed+"|"+remove_total);

    // process delete for the current page
    if (removed < remove_total) {
        // prepare progress
        scrobble_mass_remove_progress.children('.metadata-title').text('Removing');
        scrobble_mass_remove_progress.children('.metadata-display').text(removed + '/' + remove_total);

        // page counters
        var remove_page_total = Math.min(
          $jq('.chartlist button.chartlist-delete-button').length,
          remove_total-removed
        );
        var removed_page = 0;
        var requests = [];

        // submit requests asynchronously to avoid page reload
        while (removed_page < remove_page_total) {
            var f = $jq('.chartlist .chartlist-delete form').slice(removed_page).first();
            requests.push($jq.ajax({
                type: 'POST',
                url: f.attr('action'),
                data: f.serialize(),
                success: function(data) {
                  removed++;
                  nscrobbles_update();
                  scrobble_mass_remove_progress.children('.metadata-display').text(removed + '/' + remove_total);
                }
            }));
            removed_page++;
        }

        // wait for requests to complete
        $jq.when.apply($jq, requests).then(function(){
            // save state for resume
            GM_setValue('scrobble-mass-remove-resume', JSON.stringify({removed: removed, remove_total: remove_total}));

            // we need to reload here in order to bring more links
            location.reload();
        });
    }

    // we need to check this again - we may be here because of the break, waiting to reload
    if (remove_total == removed) {
        // remove resume data and clear counter
        GM_deleteValue('scrobble-mass-remove-resume');

        scrobble_mass_remove_progress.children('.metadata-title').text('');
        scrobble_mass_remove_progress.children('.metadata-display').text('');
    }
}


// ******** Resume ***********************************************************************************
var resume_data = GM_getValue('scrobble-mass-remove-resume');
// alert(JSON.parse(resume_data).removed+"/"+JSON.parse(resume_data).remove_total);
if (resume_data) {
    doRemove(JSON.parse(resume_data));
}
