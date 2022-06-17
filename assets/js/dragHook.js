
import Sortable from 'sortablejs';

export default {
  mounted() {
    let dragged;
    const hook = this;
    const selector = '#' + this.el.id;

    document.querySelectorAll('.dropzone').forEach((dropzone) => {
      new Sortable(dropzone, {
        animation: 10,
        delay: 50,
        delayOnTouchOnly: true,
        draggable: '.draggable',
        ghostClass: 'sortable-ghost',
        onEnd: function (e) {
          hook.pushEventTo(selector, "dropped", {
            draggedId: e.item.id, // id of dragged item element
            dropZoneId: e.to.id, // id of drop zone where drop occurred (not used)
            draggableIndex: e.newDraggableIndex, // 0-based index where item was dropped
          })

        },

      });
    });

  }
}

