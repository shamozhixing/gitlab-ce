(function() {
  var clearHighlights, currentTimer, defaultClass, delay, firstPiece, pieceIndex, pieces, start, stop, work;

  Turbolinks.enableProgressBar();

  defaultClass = 'tanuki-shape';

  pieces = ['path#tanuki-right-cheek', 'path#tanuki-right-eye, path#tanuki-right-ear', 'path#tanuki-nose', 'path#tanuki-left-eye, path#tanuki-left-ear', 'path#tanuki-left-cheek'];

  pieceIndex = 0;

  firstPiece = pieces[0];

  currentTimer = null;

  delay = 150;

  clearHighlights = function() {
    return $("." + defaultClass + ".highlight").attr('class', defaultClass);
  };

  start = function() {
    clearHighlights();
    pieceIndex = 0;
    if (pieces[0] !== firstPiece) {
      pieces.reverse();
    }
    if (currentTimer) {
      clearInterval(currentTimer);
    }
    return currentTimer = setInterval(work, delay);
  };

  stop = function() {
    clearInterval(currentTimer);
    return clearHighlights();
  };

  work = function() {
    clearHighlights();
    $(pieces[pieceIndex]).attr('class', defaultClass + " highlight");
    if (pieceIndex === pieces.length - 1) {
      pieceIndex = 0;
      return pieces.reverse();
    } else {
      return pieceIndex++;
    }
  };

  $(document).on('page:fetch', start);

  $(document).on('page:change', stop);

}).call(this);
