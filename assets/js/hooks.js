let Hooks = {};
Hooks.AutoScroll = {
    mounted() {
        this.pushEvent("load_messages", { screen_height: window.innerHeight }); //the amount of msgs loaded based on the screen height

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
        const element = this.el; //Save position of scroll on loading new msgs
        const isAtTop = element.scrollTop === 0;
        const previousScrollHeight = this.initialScrollHeight;
        this.initialScrollHeight = element.scrollHeight; 

        if (isAtTop) {
            element.scrollTop = element.scrollHeight - previousScrollHeight;
        }
    }
};
export default Hooks;