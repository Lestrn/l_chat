let Hooks = {};
Hooks.AutoScroll = {
    mounted() {
        this.el.scrollTop = this.el.scrollHeight;
    },
    updated() {
        this.el.scrollTop = this.el.scrollHeight;
    }
};
export default Hooks;