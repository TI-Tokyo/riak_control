Ember.TEMPLATES['application'] = Ember.Handlebars.compile('<div id="header">    <a id="riak-control-logo"></a>    <a id="basho-logo" href="http://www.basho.com" target="_blank"></a></div><div id="wrapper" class="split gui-text">    <table>        <tr>            <td id="nav-box">                <div id="navigation">                    <ul id="nav-ul">                        <li id="nav-snapshot" class="nav-li"><a {{action showSnapshot href=true}} class="gui-text-bold nav-item">Snapshot</a></li>                        <li id="nav-cluster" class="nav-li"><a {{action showCluster href=true}} class="gui-text-bold nav-item">Cluster</a></li>                        <li id="nav-ring" class="nav-li"><a {{action showRing href=true}} class="gui-text-bold nav-item">Ring</a></li>                        <li id="nav-objects" class="nav-li-disabled"><a class="gui-text-bold nav-item">Objects</a></li>                        <li id="nav-mapreduce" class="nav-li-disabled"><a class="gui-text-bold nav-item">MapReduce</a></li>                        <li id="nav-graphs" class="nav-li-disabled"><a class="gui-text-bold nav-item">Graphs</a></li>                        <li id="nav-logs" class="nav-li-disabled"><a class="gui-text-bold nav-item">Logs</a></li>                        <li id="nav-support" class="nav-li-disabled"><a class="gui-text-bold nav-item">Support</a></li>                    </ul>                    <div id="active-nav"></div>                </div>                <div id="split-bar"></div>            </td>            <td id="content-well">{{outlet}}</td>        </tr>    </table></div><!-- #wrapper --><div id="tooltips" class="hide">    <div id="inner-tooltips">        <table><tr>            <td id="display-tips" class="gui-text"></td>        </tr></table>    </div></div>');
Ember.TEMPLATES['snapshot'] = Ember.Handlebars.compile('<h1 id="snapshot-headline" class="gui-headline-bold">Current Snapshot...</h1><div class="relative">  {{#if healthyCluster}}    <div id="healthy-cluster">        <h2 class="gui-headline-bold has-cut">Your cluster is healthy.</h2>        <h3 class="gui-headline vertical-padding-small">You currently have...</h3>        <ul class="gui-text bulleted">            <li><span class="emphasize monospace">0</span> Unreachable nodes</li>            <li><span class="emphasize monospace">0</span> Incompatible nodes</li>            <li><span class="emphasize monospace">0</span> Nodes marked as down</li>            <li><span class="emphasize monospace">0</span> Nodes experiencing low memory</li>            <li>Nothing to worry about because Riak is your friend</li>        </ul>    </div>  {{else}}    <div id="unhealthy-cluster">        <h2 class="gui-headline-bold has-cut">Your cluster has problems.</h2>        {{#if areUnreachableNodes}}          <!-- Unreachable Nodes List -->          <h3 id="unreachable-nodes-title" class="gui-headline vertical-padding-small">The following nodes are currently unreachable:</h3>          <ul id="unreachable-nodes-list" class="gui-text bulleted monospace">            {{#each unreachableNodes}}              <li><a class="go-to-cluster" {{action showCluster href=true}}>{{this}}</a></li>            {{/each}}          </ul>        {{/if}}        {{#if areIncompatibleNodes}}          <!-- Incompatible Nodes List -->          <h3 id="incompatible-nodes-title" class="gui-headline vertical-padding-small">The following nodes are currently incompatible with Riak Control:</h3>          <ul id="incompatible-nodes-list" class="gui-text bulleted monospace">            {{#each incompatibleNodes}}              <li><a class="go-to-cluster" {{action showCluster href=true}}>{{this}}</a></li>            {{/each}}          </ul>        {{/if}}        {{#if areDownNodes}}          <!-- Down Nodes List -->          <h3 id="down-nodes-title" class="gui-headline vertical-padding-small">The following nodes are currently marked down:</h3>          <ul id="down-nodes-list" class="gui-text bulleted monospace">            {{#each downNodes}}              <li><a class="go-to-cluster" {{action showCluster href=true}}>{{this}}</a></li>            {{/each}}          </ul>        {{/if}}        {{#if areLowMemNodes}}          <!-- Low-Mem Nodes List -->          <h3 id="low_mem-nodes-title" class="gui-headline vertical-padding-small">The following nodes are currently experiencing low memory:</h3>          <ul id="low_mem-nodes-list" class="gui-text bulleted monospace">            {{#each lowMemNodes}}              <li><a class="go-to-cluster" {{action showCluster href=true}}>{{this}}</a></li>            {{/each}}          </ul>        {{/if}}    </div>  {{/if}}</div>');
Ember.TEMPLATES['cluster'] = Ember.Handlebars.compile('<h1 id="cluster-headline" class="gui-headline-bold">Cluster View</h1><div id="add-node">    <h3 class="gui-headline">Add Nodes to the Cluster...</h3>    <table>        <tr>            <td id="add-node-box">                <div class="gui-field gui-text">                    <div class="gui-field-bg">                        <input id="node-to-add" class="gui-field-input gui-text" type="text" name="nodeName" />                    </div>                    <div class="gui-field-cap-left"></div>                    <div class="gui-field-cap-right"></div>                </div>            </td>            <td class="button-column">                <a id="add-node-button" class="gui-point-button gui-text-bold right">                    <span class="gui-button-msg">Add Node</span>                </a>            </td>        </tr>    </table>    <div id="node-error" class="hide">        <a class="close-error gui-text"></a>        <a class="error-text offline"></a>        <a class="error-link gui-text underline" href="#"></a>    </div></div><!-- #add-node --><h2 class="gui-headline-bold has-cut">    Node List    <span id="total-number" class="gui-text"></span></h2><div id="node-list" class="hide">    <table class="list-table" id="cluster-table">        <tr class="table-head has-cut">            <td><h3 class="gui-headline">Status</h3></td>            <td><h3 class="gui-headline">Name</h3></td>            <td><h3 class="gui-headline">Actions</h3></td>            <td><h3 class="gui-headline">Partitions</h3></td>            <td><h3 class="gui-headline">Memory Usage</h3></td>        </tr>    </table></div><div class="spinner-box"><img id="cluster-spinner" class="spinner" src="/admin/ui/images/spinner.gif"></div><!-- node template --><table class="hide">    <tr class="node row-template">        <td class="status-box gui-text">            <a class="gui-light status-light"><span class="status">Joining...</span></a>        </td>        <td class="name-box gui-text">            <div class="gui-field gui-text">                <div class="gui-field-bg">                    <div class="name gui-field-input"></div>                </div>                <div class="gui-field-cap-left"></div>                <div class="gui-field-cap-right"></div>            </div>        </td>        <td class="more-actions-slider-box gui-text">            <div class="gui-slider gui-text">                <div class="gui-slider-activate"></div>                <div class="gui-slider-groove">                    <div class="gui-slider-msg isLeft">View Actions</div>                    <div class="gui-slider-msg isRight">Hide Actions</div>                </div>            </div>            <div class="gui-slider-leaving hide"></div>        </td>        <td class="gui-text ring_pct-box">            <div class="left pct-arrows pct-static">                <div class="green-pct-arrow"></div>            </div>            <div class="left gui-field gui-text pct-box">                <div class="gui-field-bg">                    <div class="i-block ring_pct gui-field-input"></div>                    <!--                    <span class="monospace gray-text">:</span>                    <div class="i-block pending_pct gui-field-input"></div>                    -->                </div>                <div class="gui-field-cap-left"></div>                <div class="gui-field-cap-right"></div>            </div>            <div class="clear"></div>        </td>        <td class="gui-text memory-box">            <div class="left membar-bg">                <div class="erlang-mem mem-color left" name=""></div>                <div class="non-erlang-mem mem-color left" name=""></div>                <div class="unknown-mem"></div>                <div class="membar-fg"></div>            </div>            <span class="free-memory left"></span>        </td>    </tr>    <tr class="more-node-actions more-actions-template">        <td>&nbsp;</td>        <td colspan="4" class="more-actions-td">            <div class="actions-pointer hide"></div>            <div class="actions-box gui-text hide">                <div class="shutdown-box left">                    <a class="shutdown-button left"></a>                    <span class="shutdown-label gui-text block left">Stop Node</span>                    <div class="clear"></div>                </div>                <div class="leave-cluster-box left">                    <a class="leave-cluster-button left"></a>                    <span class="leave-cluster-label gui-text block left">Leave Cluster</span>                    <div class="clear"></div>                </div>                <div class="markdown-box left">                    <a class="markdown-button left pressed disabled"></a>                    <span class="markdown-label gui-text block left disabled">Mark Down</span>                    <div class="clear"></div>                </div>                <div class="clear"></div>            </div>            <div class="clear"></div>        </td>    </tr></table><!-- end node template -->');
Ember.TEMPLATES['ring'] = Ember.Handlebars.compile('{{outlet partitionFilter}}<h1 id="ring-headline" class="gui-headline-bold">    Ring View    <span id="total-number" class="gui-text"></span></h1><ul class="pagination gui-text">  {{#each view.pages}}    <li><span class="paginator pageNumber"><a {{action paginateRing this}}>{{page_id}}</a></span></li>  {{/each}}</ul><div class="cut"></div><div id="partition-list" class="has-cut">    <table class="list-table" id="ring-table">        <thead>            <tr class="table-head has-cut">                <td><h3 class="gui-headline">#</h3></td>                <td><h3 class="gui-headline">Owner Node</h3></td>                <td><h3 class="gui-headline">KV</h3></td>                <td><h3 class="gui-headline">Pipe</h3></td>                <td><h3 class="gui-headline">Search</h3></td>            </tr>        </thead>        {{#collection RiakControl.PartitionView contentBinding="controller.paginatedContent"}}          {{#with view.content}}          <td class="partition-number gui-text">{{i}}</td>          <td class="owner-box gui-text">              <div class="gui-field gui-text">                  <div class="gui-field-bg">                      <div class="owner gui-field-input">{{node}}</div>                      <div class="partition-index hide">{{index}}</div>                  </div>                  <div class="gui-field-cap-left"></div>                  <div class="gui-field-cap-right"></div>              </div>          </td>          {{/with}}          {{#with view}}          <td class="kv-box gui-text">              <a {{bindAttr class="kvIndicator lightClasses"}}>                  <span class="kv-status">{{kvStatus}}</span>                  <span class="hide fallback-to"></span>              </a>          </td>          <td class="pipe-box gui-text">              <a {{bindAttr class="pipeIndicator lightClasses"}}>                  <span class="pipe-status">{{pipeStatus}}</span>                  <span class="hide fallback-to"></span>              </a>          </td>          <td class="search-box gui-text">              <a {{bindAttr class="searchIndicator lightClasses"}}>                  <span class="search-status">{{searchStatus}}</span>                  <span class="hide fallback-to"></span>              </a>          </td>          {{/with}}        {{/collection}}    </table></div><ul class="pagination gui-text pagination-bottom"></ul>');
Ember.TEMPLATES['partition_filter'] = Ember.Handlebars.compile('<div id="ring-filter" class="right">    <h4 class="gui-headline">Filter</h4>    <div class="gui-dropdown-wrapper">        <div class="gui-dropdown-bg gui-text smaller"></div>        <div class="gui-dropdown-cap left"></div>        {{view RiakControl.PartitionFilterSelectView id="filter" classNames="gui-dropdown" contentBinding="this" optionLabelPath="content.name" optionValuePath="content.value" prompt="Filter by node:"}}    </div></div>');
