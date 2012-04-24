//<debug>
Ext.Loader.setPath({
    'Ext': 'touch/src',
    'Docs': 'app',
    'TouchDocs': 'touch-app'
});
//</debug>

Ext.application({
    name: 'TouchDocs',
    appFolder: 'touch-app',

    eventPublishers: {
        touchGesture: {
            recognizers: {
                offscreenswipe: {
                    xclass: 'TouchDocs.recognizer.OffscreenSwipe'
                }
            }
        }
    },

    requires: [
        'Ext.MessageBox',
        'Docs.ClassRegistry',
        'Ext.TitleBar',
        'Ext.field.Search'
    ],

    views: [
        'Main',
        'LeftNav',
        'Content',
        'search.Dropdown'
    ],

    stores: [
        'NavigationTree',
        'Search',
        'Examples'
    ],

    models: [
        'TreeItem',
        'SearchResult'
    ],

    controllers: [
        'Navigation',
        'LeftNav',
        'Search'
    ],

    icon: {
        57: 'resources/touch-icons/Icon.png',
        72: 'resources/touch-icons/Icon~ipad.png',
        114: 'resources/touch-icons/Icon@2x.png',
        144: 'resources/touch-icons/Icon~ipad@2x.png'
    },

    phoneStartupScreen: 'resources/touch-loading/Homescreen.jpg',
    tabletStartupScreen: 'resources/touch-loading/Homescreen~ipad.jpg',

    launch: function() {
        // Destroy the #appLoadingIndicator element
        Ext.fly('appLoadingIndicator').destroy();

        Ext.getStore('NavigationTree').setNavigationData(Docs.data);
        Ext.getStore('Examples').loadExamples();

        // Initialize the main view
        Ext.Viewport.add(Ext.create('TouchDocs.view.Main'));

        if (window.location.hash === '') {
            TouchDocs.app.getHistory().add(Ext.create('Ext.app.Action', {
                url: '!/home'
            }));
        }

        // setInterval(function(){
        //     Ext.DomQuery.select('link')[0].href = "resources/css/touch.css?" + Math.ceil(Math.random() * 100000000)
        // }, 1000);
    },

    onUpdated: function() {
        Ext.Msg.confirm(
            "Application Update",
            "This application has just successfully been updated to the latest version. Reload now?",
            function() {
                window.location.reload();
            }
        );
    }
});
