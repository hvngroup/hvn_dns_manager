<!-- Toast Container -->
<div class="toast-container position-fixed bottom-0 end-0 p-3" style="z-index: 1080" x-data="{
    show: false,
    title: '',
    msg: '',
    type: 'success',
    timeout: null,
    
    showToastHandler(e) {
        this.title = e.detail.title;
        this.msg = e.detail.msg;
        this.type = e.detail.type || 'success';
        this.show = true;
        
        if(this.timeout) clearTimeout(this.timeout);
        this.timeout = setTimeout(() => { this.show = false; }, 3000);
    }
}" @show-toast.window="showToastHandler($event)">
    <div class="toast align-items-center text-white border-0" :class="{ 'show': show, ['bg-' + type]: true }" :style="show ? 'display: block;' : 'display: none;'" role="alert" aria-live="assertive" aria-atomic="true">
        <div class="d-flex">
            <div class="toast-body">
                <strong x-text="title"></strong><br>
                <span x-html="msg"></span>
            </div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" @click="show = false" aria-label="Close"></button>
        </div>
    </div>
</div>

<script>
    // Keeping function for direct call compatibility if any
    function showToast(title, msg, type = 'success') {
        window.dispatchEvent(new CustomEvent('show-toast', { detail: { title: title, msg: msg, type: type } }));
    }
</script>
