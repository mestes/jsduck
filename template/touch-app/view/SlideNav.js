/**
 * Container with main content area and sidebar that can be hidden/shown.
 *
 * The sidebar is hidden/shown when user swipes from the side of main content area.
 * Additionally #setOpen and #toggle methods can be used.
 */
Ext.define("TouchDocs.view.SlideNav", {
    extend: 'Ext.Container',

    config: {
        layout: 'fit',
        /**
         * @cfg
         * True to make the sideContainer initially visible.
         * @accessor
         */
        open: false,
        /**
         * @cfg
         * The side container that can be hidden or shown using #setOpen method.
         * This container must have width specified.
         * @accessor
         */
        sideContainer: null,
        /**
         * @cfg
         * The main container.
         * @accessor
         */
        container: null
    },

    applySideContainer: function(config) {
        return Ext.factory(config);
    },

    updateSideContainer: function(newSideContainer, oldSideContainer) {
        if (newSideContainer) {
            this.add(newSideContainer);
        }

        if (oldSideContainer) {
            this.remove(oldSideContainer);
        }
    },

    applyContainer: function(config) {
        return Ext.factory(config);
    },

    updateContainer: function(newContainer, oldContainer) {
        if (newContainer) {
            newContainer.setZIndex(3);
            this.add(newContainer);

            newContainer.element.on({
                tap: this.onContainerTap,
                dragstart: this.onDragStart,
                drag: this.onDrag,
                dragend: this.onDragEnd,
                scope: this
            });
        }

        if (oldContainer) {
            this.remove(oldContainer);
        }
    },

    /**
     * Toggles the visibility of #sideContainer.
     */
    toggle: function() {
        this.setOpen(!this.getOpen());
    },

    onContainerTap: function(e) {
        if (!this.getOpen()) {
            return;
        }

        this.setOpen(false);
        e.stopEvent();
    },

    onDragStart: function(e) {
        var touch = e.changedTouches[0],
            startX = touch.pageX;

        if (startX < 50 && !this.getOpen()) {
            this.canOpen = true;
            this.getContainer().getScrollable().getScroller().setDisabled(true);
        } else {
            this.canOpen = false;
            this.onContainerTap(e);
        }
    },

    onDrag: function(e) {
        var touch = e.changedTouches[0],
            startX = Math.min(touch.pageX, this.getSideContainer().getWidth());

        if (this.lastX && startX > this.lastX) {
            this.direction = 'right';
        } else {
            this.direction = 'left';
        }
        this.lastX = startX;

        if (this.canOpen) {
            this.getContainer().element.dom.style.setProperty('-webkit-transform', 'translateX(' + startX + 'px)', 'important');
        }
    },

    onDragEnd: function(e) {
        if (this.canOpen === false) {
            return;
        }

        this.canOpen = false;

        var touch = e.changedTouches[0],
            sideContainerWidth = this.getSideContainer().getWidth(),
            startX = Math.min(touch.pageX, sideContainerWidth);

        if ((this.direction === 'right') || startX > (sideContainerWidth / 2)) {
            this.setOpen(true);
        } else {
            this.setOpen(false);
            this.updateOpen(false);
        }
    },

    updateOpen: function(newOpen) {
        // don't animate when initially closed
        if (!this.initialized && !newOpen) {
            return;
        }

        this.animate(newOpen);
    },

    animate: function(open) {
        Ext.Animator.run({
            element: this.getContainer().element,
            easing: 'ease-out',
            duration: 250,
            to: {
                transform: {
                    translateX: open ? this.getSideContainer().getWidth() : 0
                }
            },
            onEnd: open ? null : function() {
                // re-enable scrolling of main container once left sideContainer has closed
                if (this.getContainer().getScrollable()) {
                    this.getContainer().getScrollable().getScroller().setDisabled(false);
                }
            },
            preserveEndState: true,
            scope: this
        });
    }
});
