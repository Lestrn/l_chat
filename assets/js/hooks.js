let Hooks = {};
Hooks.AutoScroll = {
    mounted() {
        this.el.addEventListener("scroll", () => {
            if (this.el.scrollTop === 0) {
                this.pushEvent("load_more_messages");
            }
        });
        
        this.initialScrollHeight = this.el.scrollHeight;

        this.handleEvent("scroll_down", (params) => {
            this.el.scrollTop = this.el.scrollHeight;
        });

    },
    updated() {
        const element = this.el;
        const isAtTop = element.scrollTop === 0;
        const previousScrollHeight = this.initialScrollHeight;
        this.initialScrollHeight = element.scrollHeight; 

        if (isAtTop) {
            element.scrollTop = element.scrollHeight - previousScrollHeight;
        }
    }
};
export default Hooks;