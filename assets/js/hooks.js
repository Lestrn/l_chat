let Hooks = {};
Hooks.AutoScroll = {
    mounted() {
        this.pushEvent("load_messages", { screen_height: window.innerHeight }); //the amount of msgs loaded based on the screen height

        this.el.addEventListener("scroll", () => {
            if (this.el.scrollTop === 0) {
                this.pushEvent("load_more_messages");
            }
        });

        this.el.addEventListener("scroll", () => {
            this.scrollDown = this.el.scrollHeight - this.el.scrollTop <= this.el.clientHeight + 1; // check if user is reading msgs above
        })

        this.initialScrollHeight = this.el.scrollHeight;

        this.handleEvent("scroll_down", (params) => { //if user doesnt read msgs above scroll down
            if (params.current_user_owns_msg) {
                this.el.scrollTop = this.el.scrollHeight;
                return;
            }

            if (this.scrollDown) {
                this.el.scrollTop = this.el.scrollHeight;
            }
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

Hooks.ContextMenuHook = {
    mounted() {
        let contextMenu = document.getElementById("context-menu");
        let currentUserId = this.el.dataset.currentUserId;
        let messageUserId = this.el.dataset.messageUserId;

        this.el.addEventListener("contextmenu", async (event) => {
            event.preventDefault();
            let messageId = this.el.id;
            if (currentUserId === messageUserId) {
                try {
                    await this.pushEvent("set_msg_id_for_context", { "message-id": messageId.replace(/\D/g, "") });
                    contextMenu.style.top = `${event.clientY}px`;
                    contextMenu.style.left = `${event.clientX}px`;
                    contextMenu.classList.remove("hidden");
                } catch (error) {
                    console.error("Error sending event:", error);
                }
            }
            else {
                contextMenu.classList.add("hidden");
            }
        });

        document.addEventListener("click", () => {
            contextMenu.classList.add("hidden");
        });
    }
}

export default Hooks;