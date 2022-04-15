/*
 * Copyright (c) 2012, IETR/INSA of Rennes
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *   * Neither the name of the IETR/INSA of Rennes nor the names of its
 *     contributors may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
package net.sf.orcc.ui.console;

import java.io.IOException;
import java.util.logging.Handler;
import java.util.logging.LogRecord;

import net.sf.orcc.OrccRuntimeException;
import net.sf.orcc.util.OrccLogger;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.widgets.Display;
import org.eclipse.ui.console.IConsole;
import org.eclipse.ui.console.IOConsole;
import org.eclipse.ui.console.IOConsoleOutputStream;

/**
 * This class declare a simple Handler to print messages in the Eclipse console.
 * 
 * @author mpelcat
 * @author mwipliez
 * @author Antoine Lorence
 * @see java.util.logging.Handler
 */
public class OrccUiConsoleHandler extends Handler {

	IOConsole console = null;

	class PublishProcess implements Runnable {

		LogRecord record;

		/**
		 * 
		 */
		public PublishProcess(LogRecord record) {
			this.record = record;
		}

		@Override
		public void run() {
			String message = getFormatter().format(record);
			IOConsoleOutputStream outStream = console.newOutputStream();

			if (record.getLevel().intValue() == OrccLogger.SEVERE.intValue()) {
				outStream.setColor(new Color(null, 255, 0, 0));
			} else if (record.getLevel().intValue() == OrccLogger.WARNING
					.intValue()) {
				outStream.setColor(new Color(null, 250, 133, 50));
			} else if (record.getLevel().intValue() == OrccLogger.DEBUG
					.intValue()) {
				outStream.setColor(new Color(null, 133, 200, 62));
			} else if (record.getLevel().intValue() == OrccLogger.NOTICE
					.intValue()) {
				outStream.setColor(new Color(null, 0, 0, 156));
			}

			try {
				outStream.write(message);
				outStream.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}

	/**
	 * Build the Eclipse console handler
	 * 
	 * @param currentConsole
	 *            the current eclipse ProcessConsole
	 * 
	 */
	public OrccUiConsoleHandler(IConsole currentConsole) {
		super();
		if (currentConsole instanceof IOConsole) {
			this.console = (IOConsole) currentConsole;
			console.activate();

		} else {
			throw new OrccRuntimeException(
					"Invalid console passed in parameter");
		}
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see java.util.logging.Handler#close()
	 */
	@Override
	public void close() throws SecurityException {
		console.destroy();
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see java.util.logging.Handler#flush()
	 */
	@Override
	public void flush() {
		console.clearConsole();
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see java.util.logging.Handler#publish(java.util.logging.LogRecord)
	 */
	@Override
	public void publish(LogRecord record) {

		if (!isLoggable(record)) {
			return;
		}

		Display.getDefault().syncExec(new PublishProcess(record));
	}
}
