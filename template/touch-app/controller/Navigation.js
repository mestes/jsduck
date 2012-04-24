/**
 * Handles navigation to different pages in app when browser history
 * is navigated.
 */
Ext.define('TouchDocs.controller.Navigation', {
    extend: 'Ext.app.Controller',
    requires: ['Ext.data.JsonP'],

    config: {
        routes: {
            '!/api/:cls': {
                action: 'showClass',
                conditions: {
                    ':cls': "[0-9a-zA-Z\.]+"
                }
            },
            '!/api/:method': {
                action: 'showClassMember',
                conditions: {
                    ':method': "[0-9a-zA-Z\.\-]+"
                }
            },
            '!/guide/:name': {
                action: 'showGuide',
                conditions: {
                    ':name': "[0-9a-zA-Z_]+"
                }
            },
            '!/guide/:name:section': {
                action: 'showGuideSection',
                conditions: {
                    ':section': "-section-[0-9]+"
                }
            },
            '!/video/:name': 'showVideo',
            '!/home': 'showHome',
            '!/example': 'showExamples'
        },

        refs: {
            content: 'content',
            navigationTree: 'leftNav'
        },

        control: {
            'content list': {
                itemtap: 'showExample'
            }
        }
    },

    showGuide: function(name, callback, scope) {
        if (this.currentContent === name) {
            if (callback) {
                callback.call(scope);
            }
            else {
                this.getContent().scrollToTop();
            }
            return;
        }

        this.currentContent = name;
        this.getNavigationTree().setActiveNode({ type: 'guide', name: name });

        this.mask();
        Ext.data.JsonP.request({
            url: "guides/" + name + "/README.js",
            callbackName: name,
            success: function(json) {
                this.getContent().loadGuide(json.title, json.guide);
                this.unmask();
                callback && callback.call(scope);
            },
            failure: function() {
                this.unmask();
            },
            scope: this
        });
    },

    showGuideSection: function(name, section) {
        this.showGuide(name, function() {
            this.getContent().scrollToId(name + section);
        }, this);
    },

    showClass: function(name, callback, scope) {
        if (this.currentContent === name) {
            if (callback) {
                callback.call(scope);
            }
            else {
                this.getContent().scrollToTop();
            }
            return;
        }

        this.currentContent = name;
        this.getNavigationTree().setActiveNode({ className: name });

        this.mask();
        Ext.data.JsonP.request({
            url: "output/" + name + ".js",
            callbackName: name.replace(/\./g, '_'),
            success: function(json) {
                this.getContent().loadClass(json.name, json.html);
                this.unmask();
                callback && callback.call(scope);
            },
            failure: function() {
                this.unmask();
            },
            scope: this
        });
    },

    showClassMember: function(name) {
        // The full member name consist of dash-separated parts
        // (the static part is optional):
        //
        //    ClassName - (static - ) type - name
        //
        var split = name.split('-');
        var cls = split.shift();
        var member = split.join("-");

        this.showClass(cls, function() {
            this.getContent().scrollToId(member, 'open');
        }, this);
    },

    showVideo: function(name) {
        this.currentContent = name;

        var idx = Ext.getStore('NavigationTree').findBy(function(record, id) {
            if (record.get) {
                return record.get('type') === 'video' && record.get('name') === name;
            } else {
                return false;
            }
        });
        var record = Ext.getStore('NavigationTree').getAt(idx);

        if (record) {
            this.getNavigationTree().setActiveNode(record);
            this.getContent().loadVideo(record.get('title'), record.get('videoId'), record.get('description'));
        }
    },

    showHome: function() {
        this.currentContent = 'home';

        this.getNavigationTree().setActiveNode({ type: 'home' });
        this.getContent().loadHome();
    },

    showExamples: function() {
        this.currentContent = 'examples';

        this.getNavigationTree().setActiveNode({ type: 'examples' });
        this.getContent().loadExamples();
    },

    showExample: function(view, idx, target, record) {
        Ext.Msg.confirm("Example", "This example will open in a new window", function(result) {
            if (result === "yes") {
                window.location = record.get('url');
            }
        });
    },

    // helpers to mask/unmask the viewport

    mask: function() {
        Ext.Viewport.setMasked({ xtype: 'loadmask' });
    },

    unmask: function() {
        Ext.Viewport.setMasked(false);
    }
});
