
import Sortable from 'sortablejs';

export default {
  mounted() {
    let dragged;
    const hook = this;
    const select = '#' + this.el.id;

    document.querySelectorAll('.dropzone').forEach((dropzone) => {
      new Sortable(dropzone, {
        animation: 10,
        delay: 50,
        delayOnTouchOnly: true,
        draggable: '.draggable',
        ghostClass: 'sortable-ghost'
      });
    });

  }
}

